#import <Foundation/Foundation.h>

#include <exception>
#include <limits.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

static const char *PEHelpLink = "https://github.com/LeninAsto/FNF-PlusEngine";
static volatile sig_atomic_t sHandlingCrash = 0;
static NSUncaughtExceptionHandler *sPreviousExceptionHandler = 0;
static std::terminate_handler sPreviousTerminateHandler = 0;
static char sLogsDirectory[PATH_MAX] = {0};
static char sSignalLogPath[PATH_MAX] = {0};
static unsigned char sAlternateSignalStack[SIGSTKSZ * 4];

struct PESignalRegistration
{
	int signalNumber;
	const char *signalName;
	struct sigaction previousAction;
};

static PESignalRegistration sHandledSignals[] = {
	{SIGABRT, "SIGABRT", {}},
	{SIGILL, "SIGILL", {}},
	{SIGSEGV, "SIGSEGV", {}},
	{SIGFPE, "SIGFPE", {}},
	{SIGBUS, "SIGBUS", {}},
	{SIGTRAP, "SIGTRAP", {}}
};

static size_t PEHandledSignalCount()
{
	return sizeof(sHandledSignals) / sizeof(sHandledSignals[0]);
}

static PESignalRegistration *PEFindSignalRegistration(int signalNumber)
{
	for (size_t index = 0; index < PEHandledSignalCount(); ++index)
	{
		if (sHandledSignals[index].signalNumber == signalNumber)
		{
			return &sHandledSignals[index];
		}
	}

	return 0;
}

static NSString *PELogsDirectory()
{
	NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *baseDirectory = [directories firstObject];

	if (baseDirectory == nil || [baseDirectory length] == 0)
	{
		baseDirectory = NSTemporaryDirectory();
	}

	NSString *logsDirectory = [baseDirectory stringByAppendingPathComponent:@"logs"];
	[[NSFileManager defaultManager] createDirectoryAtPath:logsDirectory
							withIntermediateDirectories:YES
							 attributes:nil
							      error:nil];
	return logsDirectory;
}

static NSString *PETimestampString()
{
	time_t now = time(NULL);
	struct tm localNow;
	localtime_r(&now, &localNow);

	char buffer[32];
	strftime(buffer, sizeof(buffer), "%Y-%m-%d_%H-%M-%S", &localNow);
	return [NSString stringWithUTF8String:buffer];
}

static void PEPrepareLogPaths()
{
	@autoreleasepool
	{
		NSString *logsDirectory = PELogsDirectory();
		if (![logsDirectory getFileSystemRepresentation:sLogsDirectory maxLength:sizeof(sLogsDirectory)])
		{
			strncpy(sLogsDirectory, ".", sizeof(sLogsDirectory) - 1);
		}

		NSString *signalPath = [logsDirectory stringByAppendingPathComponent:@"crashNATIVE_iOS_signal.txt"];
		if (![signalPath getFileSystemRepresentation:sSignalLogPath maxLength:sizeof(sSignalLogPath)])
		{
			strncpy(sSignalLogPath, "crashNATIVE_iOS_signal.txt", sizeof(sSignalLogPath) - 1);
		}
	}
}

static void PEWriteObjectiveCLog(NSString *kind, NSString *title, NSString *message, NSString *stackTrace)
{
	@autoreleasepool
	{
		NSString *logsDirectory = PELogsDirectory();
		NSString *timestamp = PETimestampString();
		NSString *fileName = [NSString stringWithFormat:@"crashNATIVE_iOS_%@_%@.txt", kind, timestamp];
		NSString *latestName = [NSString stringWithFormat:@"crashNATIVE_iOS_%@_last.txt", kind];
		NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];
		NSString *latestPath = [logsDirectory stringByAppendingPathComponent:latestName];

		NSMutableString *logText = [NSMutableString string];
		[logText appendString:@"=== NATIVE IOS CRASH ===\n"];
		[logText appendFormat:@"Type       : %@\n", title != nil ? title : @"Unknown"];
		[logText appendFormat:@"Message    : %@\n", message != nil ? message : @"No message"];

		if (stackTrace != nil && [stackTrace length] > 0)
		{
			[logText appendString:@"\nStack trace:\n"];
			[logText appendString:stackTrace];
			[logText appendString:@"\n"];
		}

		[logText appendString:@"\n========================\n"];
		[logText appendString:@"Please report this crash at:\n"];
		[logText appendFormat:@"%s\n", PEHelpLink];

		NSError *writeError = nil;
		[logText writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
		[logText writeToFile:latestPath atomically:YES encoding:NSUTF8StringEncoding error:nil];

		const char *utf8Log = [logText UTF8String];
		if (utf8Log != NULL)
		{
			fprintf(stderr, "%s\n", utf8Log);
			fflush(stderr);
		}

		if (writeError != nil)
		{
			fprintf(stderr, "Failed to write iOS crash log: %s\n", [[writeError localizedDescription] UTF8String]);
			fflush(stderr);
		}
	}
}

static void PEWriteSignalLog(int signalNumber, siginfo_t *info)
{
	const char *signalName = "UNKNOWN";
	int signalCode = 0;
	unsigned long long signalAddress = 0;

	if (PESignalRegistration *registration = PEFindSignalRegistration(signalNumber))
	{
		signalName = registration->signalName;
	}

	if (info != 0)
	{
		signalCode = info->si_code;
		signalAddress = (unsigned long long)(uintptr_t)info->si_addr;
	}

	char buffer[1024];
	int length = snprintf(
		buffer,
		sizeof(buffer),
		"=== NATIVE IOS CRASH ===\n"
		"Type       : Signal\n"
		"Signal     : %s (%d)\n"
		"Code       : %d\n"
		"Address    : 0x%llx\n"
		"Note       : Fatal signal handlers only write minimal data safely.\n"
		"\n========================\n"
		"Please report this crash at:\n"
		"%s\n",
		signalName,
		signalNumber,
		signalCode,
		signalAddress,
		PEHelpLink
	);

	if (length <= 0)
	{
		return;
	}

	size_t bytesToWrite = (size_t)((length < (int)sizeof(buffer)) ? length : ((int)sizeof(buffer) - 1));
	const char *path = sSignalLogPath[0] != '\0' ? sSignalLogPath : "crashNATIVE_iOS_signal.txt";
	int fileDescriptor = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fileDescriptor >= 0)
	{
		(void)write(fileDescriptor, buffer, bytesToWrite);
		(void)close(fileDescriptor);
	}

	(void)write(STDERR_FILENO, buffer, bytesToWrite);
}

static void PEForwardSignal(int signalNumber)
{
	if (PESignalRegistration *registration = PEFindSignalRegistration(signalNumber))
	{
		sigaction(signalNumber, &registration->previousAction, 0);
	}
	else
	{
		signal(signalNumber, SIG_DFL);
	}

	kill(getpid(), signalNumber);
	_exit(128 + signalNumber);
}

static void PEHandleSignal(int signalNumber, siginfo_t *info, void *context)
{
	(void)context;

	if (sHandlingCrash)
	{
		_exit(128 + signalNumber);
	}

	sHandlingCrash = 1;
	PEWriteSignalLog(signalNumber, info);
	PEForwardSignal(signalNumber);
}

static void PEHandleUncaughtException(NSException *exception)
{
	if (sHandlingCrash)
	{
		abort();
	}

	sHandlingCrash = 1;
	NSString *stackTrace = [[exception callStackSymbols] componentsJoinedByString:@"\n"];
	PEWriteObjectiveCLog(@"exception", [exception name], [exception reason], stackTrace);

	if (sPreviousExceptionHandler != 0 && sPreviousExceptionHandler != PEHandleUncaughtException)
	{
		sPreviousExceptionHandler(exception);
	}

	abort();
}

static void PEHandleTerminate()
{
	if (sHandlingCrash)
	{
		_exit(134);
	}

	sHandlingCrash = 1;
	NSString *reason = @"std::terminate was called.";
	std::exception_ptr currentException = std::current_exception();

	if (currentException)
	{
		try
		{
			std::rethrow_exception(currentException);
		}
		catch (const std::exception &exception)
		{
			reason = [NSString stringWithUTF8String:exception.what()];
		}
		catch (...)
		{
			reason = @"Unknown non-std C++ exception reached std::terminate.";
		}
	}

	NSString *stackTrace = [[NSThread callStackSymbols] componentsJoinedByString:@"\n"];
	PEWriteObjectiveCLog(@"terminate", @"std::terminate", reason, stackTrace);

	if (sPreviousTerminateHandler != 0 && sPreviousTerminateHandler != PEHandleTerminate)
	{
		sPreviousTerminateHandler();
	}

	abort();
}

extern "C" bool NativeCrashHandlerIOS_Install()
{
	static bool installed = false;
	if (installed)
	{
		return true;
	}

	installed = true;
	PEPrepareLogPaths();

	stack_t alternateStack;
	memset(&alternateStack, 0, sizeof(alternateStack));
	alternateStack.ss_sp = sAlternateSignalStack;
	alternateStack.ss_size = sizeof(sAlternateSignalStack);
	(void)sigaltstack(&alternateStack, 0);

	sPreviousExceptionHandler = NSGetUncaughtExceptionHandler();
	NSSetUncaughtExceptionHandler(PEHandleUncaughtException);
	sPreviousTerminateHandler = std::set_terminate(PEHandleTerminate);

	struct sigaction action;
	memset(&action, 0, sizeof(action));
	sigemptyset(&action.sa_mask);
	action.sa_flags = SA_SIGINFO | SA_ONSTACK;
	action.sa_sigaction = PEHandleSignal;

	for (size_t index = 0; index < PEHandledSignalCount(); ++index)
	{
		sigaction(sHandledSignals[index].signalNumber, &action, &sHandledSignals[index].previousAction);
	}

	return true;
}