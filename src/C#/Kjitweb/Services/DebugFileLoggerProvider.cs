namespace KjitWeb.Services;

public sealed class DebugFileLoggerProvider : ILoggerProvider
{
    private readonly DebugLogFileWriter _writer;

    public DebugFileLoggerProvider(DebugLogFileWriter writer)
    {
        _writer = writer;
    }

    public ILogger CreateLogger(string categoryName)
    {
        return new DebugFileLogger(categoryName, _writer);
    }

    public void Dispose()
    {
    }

    private sealed class DebugFileLogger : ILogger
    {
        private readonly string _categoryName;
        private readonly DebugLogFileWriter _writer;

        public DebugFileLogger(string categoryName, DebugLogFileWriter writer)
        {
            _categoryName = categoryName;
            _writer = writer;
        }

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull
        {
            return null;
        }

        public bool IsEnabled(LogLevel logLevel)
        {
            return logLevel >= LogLevel.Information;
        }

        public void Log<TState>(
            LogLevel logLevel,
            EventId eventId,
            TState state,
            Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            if (!IsEnabled(logLevel))
            {
                return;
            }

            var message = formatter(state, exception);
            _writer.WriteError(logLevel, _categoryName, message, exception);
        }
    }
}