package funkin.util;

/**
 * Native C++ crash handler for Windows.
 *
 * Installs a low-level SEH (Structured Exception Handling) filter that
 * catches fatal crashes that bypass Haxe's exception system entirely:
 *   - ACCESS_VIOLATION (null pointer dereference at C level)
 *   - STACK_OVERFLOW   (infinite recursion, very deep call stack)
 *   - HEAP_CORRUPTION  (use-after-free, buffer overruns)
 *
 * On crash it writes  logs/crashNATIVE_<timestamp>.txt  to disk BEFORE the
 * process terminates, so the information survives the crash.
 *
 * Usage:  NativeCrashHandler.install();   (call from Main.hx or CrashHandler.init)
 */
#if (windows && cpp)
@:buildXml('
<target id="haxe">
    <lib name="dbghelp.lib" if="windows" />
</target>
')
@:cppFileCode('
#ifndef NATIVE_CRASH_HANDLER_CPP
#define NATIVE_CRASH_HANDLER_CPP

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <DbgHelp.h>
#include <string>
#include <sstream>
#include <fstream>
#include <ctime>
#include <direct.h>   // _mkdir

#pragma comment(lib, "DbgHelp.lib")

// Returns a human-readable name for an exception code.
static const char* NativeCrashHandler_ExceptionName(DWORD code)
{
    switch (code)
    {
        case EXCEPTION_ACCESS_VIOLATION:         return "ACCESS_VIOLATION (null pointer / bad memory access)";
        case EXCEPTION_STACK_OVERFLOW:           return "STACK_OVERFLOW (infinite recursion / stack too deep)";
        case EXCEPTION_ARRAY_BOUNDS_EXCEEDED:    return "ARRAY_BOUNDS_EXCEEDED";
        case EXCEPTION_DATATYPE_MISALIGNMENT:    return "DATATYPE_MISALIGNMENT";
        case EXCEPTION_FLT_DIVIDE_BY_ZERO:       return "FLT_DIVIDE_BY_ZERO";
        case EXCEPTION_INT_DIVIDE_BY_ZERO:       return "INT_DIVIDE_BY_ZERO";
        case EXCEPTION_INT_OVERFLOW:             return "INT_OVERFLOW";
        case EXCEPTION_ILLEGAL_INSTRUCTION:      return "ILLEGAL_INSTRUCTION";
        case EXCEPTION_PRIV_INSTRUCTION:         return "PRIVILEGED_INSTRUCTION";
        case EXCEPTION_IN_PAGE_ERROR:            return "IN_PAGE_ERROR";
        case EXCEPTION_NONCONTINUABLE_EXCEPTION: return "NONCONTINUABLE_EXCEPTION";
        case EXCEPTION_BREAKPOINT:               return "BREAKPOINT";
        case 0xC0000194:                         return "POSSIBLE_DEADLOCK";
        case 0xC0000409:                         return "STACK_BUFFER_OVERRUN";
        default:                                 return "UNKNOWN_EXCEPTION";
    }
}

// Writes a stack-walk into the output stream.
static void NativeCrashHandler_WriteStack(std::ostringstream& out, CONTEXT* ctx)
{
    HANDLE hProcess = GetCurrentProcess();
    HANDLE hThread  = GetCurrentThread();

    SymInitialize(hProcess, NULL, TRUE);
    SymSetOptions(SYMOPT_LOAD_LINES | SYMOPT_UNDNAME);

    STACKFRAME64 frame;
    ZeroMemory(&frame, sizeof(frame));

#ifdef _M_X64
    DWORD machineType      = IMAGE_FILE_MACHINE_AMD64;
    frame.AddrPC.Offset    = ctx->Rip;
    frame.AddrFrame.Offset = ctx->Rbp;
    frame.AddrStack.Offset = ctx->Rsp;
#elif defined(_M_IX86)
    DWORD machineType      = IMAGE_FILE_MACHINE_I386;
    frame.AddrPC.Offset    = ctx->Eip;
    frame.AddrFrame.Offset = ctx->Ebp;
    frame.AddrStack.Offset = ctx->Esp;
#else
    out << "  (stack walk not supported on this architecture)\\n";
    SymCleanup(hProcess);
    return;
#endif

    frame.AddrPC.Mode    = AddrModeFlat;
    frame.AddrFrame.Mode = AddrModeFlat;
    frame.AddrStack.Mode = AddrModeFlat;

    const int MAX_FRAMES = 64;
    out << "Stack trace (up to " << MAX_FRAMES << " frames):\\n";

    // Symbol info buffer
    char symBuf[sizeof(SYMBOL_INFO) + MAX_SYM_NAME * sizeof(TCHAR)];
    SYMBOL_INFO* sym = (SYMBOL_INFO*)symBuf;
    sym->SizeOfStruct = sizeof(SYMBOL_INFO);
    sym->MaxNameLen   = MAX_SYM_NAME;

    IMAGEHLP_LINE64 lineInfo;
    ZeroMemory(&lineInfo, sizeof(lineInfo));
    lineInfo.SizeOfStruct = sizeof(IMAGEHLP_LINE64);

    for (int i = 0; i < MAX_FRAMES; i++)
    {
        if (!StackWalk64(machineType, hProcess, hThread, &frame, ctx,
                         NULL, SymFunctionTableAccess64, SymGetModuleBase64, NULL))
            break;
        if (frame.AddrPC.Offset == 0) break;

        out << "  #" << i << " 0x" << std::hex << frame.AddrPC.Offset << std::dec;

        DWORD64 displacement = 0;
        if (SymFromAddr(hProcess, frame.AddrPC.Offset, &displacement, sym))
            out << " " << sym->Name;

        DWORD lineDisp = 0;
        if (SymGetLineFromAddr64(hProcess, frame.AddrPC.Offset, &lineDisp, &lineInfo))
            out << " (" << lineInfo.FileName << ":" << lineInfo.LineNumber << ")";

        out << "\\n";
    }

    SymCleanup(hProcess);
}

// The actual SEH filter callback — runs on the crashing thread.
static LONG WINAPI NativeCrashHandler_Filter(EXCEPTION_POINTERS* ep)
{
    // EXCEPTION_STACK_OVERFLOW is special: do NOT try to allocate on the
    // stack inside the filter (it is already exhausted).  Write only minimal
    // information.
    bool isStackOverflow = (ep && ep->ExceptionRecord &&
                            ep->ExceptionRecord->ExceptionCode == EXCEPTION_STACK_OVERFLOW);

    std::ostringstream msg;
    msg << "=== NATIVE C++ CRASH ===\\n";

    if (ep && ep->ExceptionRecord)
    {
        DWORD code = ep->ExceptionRecord->ExceptionCode;
        msg << "Exception  : " << NativeCrashHandler_ExceptionName(code)
            << " (0x" << std::hex << code << std::dec << ")\\n";

        if (code == EXCEPTION_ACCESS_VIOLATION && ep->ExceptionRecord->NumberParameters >= 2)
        {
            ULONG_PTR rw   = ep->ExceptionRecord->ExceptionInformation[0];
            ULONG_PTR addr = ep->ExceptionRecord->ExceptionInformation[1];
            msg << "Access     : " << (rw == 0 ? "READ" : (rw == 1 ? "WRITE" : "EXECUTE"))
                << " at address 0x" << std::hex << addr << std::dec << "\\n";
            if (addr == 0)
                msg << "             (likely a null pointer dereference)\\n";
        }
    }
    else
    {
        msg << "Exception  : (no exception record)\\n";
    }

    if (!isStackOverflow && ep && ep->ContextRecord)
    {
        msg << "\\n";
        NativeCrashHandler_WriteStack(msg, ep->ContextRecord);
    }
    else if (isStackOverflow)
    {
        msg << "\\n(Stack walk skipped for STACK_OVERFLOW to avoid secondary crash)\\n";
        msg << "Most likely cause: infinite recursion or a function calling itself\\n";
        msg << "infinitely deep (check for recursive state callbacks, etc.)\\n";
    }

    std::string log = msg.str();

    // Print to stdout/stderr so it appears in the console.
    fprintf(stderr, "\\n%s\\n", log.c_str());
    fprintf(stderr, "========================\\n");
    fflush(stderr);

    // Write to file: logs/crashNATIVE_<timestamp>.txt
    _mkdir("logs");
    time_t now = time(NULL);
    char timeBuf[64];
    strftime(timeBuf, sizeof(timeBuf), "%Y-%m-%d_%H-%M-%S", localtime(&now));
    std::string path = std::string("logs/crashNATIVE_") + timeBuf + ".txt";

    std::ofstream file(path);
    if (file.is_open())
    {
        file << log << "\\n";
        file << "========================\\n";
        file << "Please report this crash at:\\n";
        file << "https://github.com/LeninAsto/FNF-PlusEngine\\n";
        file.close();

        fprintf(stderr, "Crash log saved to: %s\\n", path.c_str());
        fflush(stderr);
    }

    // EXCEPTION_CONTINUE_SEARCH  →  let Windows show the "app has stopped working" dialog
    // EXCEPTION_EXECUTE_HANDLER  →  eat the exception, terminate silently
    // We use CONTINUE_SEARCH so the OS can generate a Windows Error Report (WER) minidump.
    return EXCEPTION_CONTINUE_SEARCH;
}

// Called once from Haxe to install the filter.
static bool NativeCrashHandler_Install()
{
    SetUnhandledExceptionFilter(NativeCrashHandler_Filter);
    return true;
}

#endif // NATIVE_CRASH_HANDLER_CPP
')
#end

#if (ios && cpp)
@:buildXml('
<files id="haxe">
    <file name="source/funkin/util/ios/NativeCrashHandlerIOS.mm" />
</files>
')
@:headerCode('
extern "C" bool NativeCrashHandlerIOS_Install();
')
#end
class NativeCrashHandler
{
	/**
     * Installs the native platform crash handler.
	 * Must be called as early as possible in Main.hx — ideally before any
	 * other code runs — so it catches crashes in all subsequent code.
	 *
     * On unsupported targets this is a no-op.
	 */
	public static function install():Void
	{
		#if (windows && cpp)
		untyped __cpp__('NativeCrashHandler_Install()');
        #elseif (ios && cpp)
        untyped __cpp__('NativeCrashHandlerIOS_Install()');
		#end
	}
}
