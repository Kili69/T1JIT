/*
 * File: DebugFileLoggerProvider.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete provider and logger documentation.
 */

namespace KjitWeb.Services;

/// <summary>
/// Creates category-specific loggers that write informational and higher-severity events
/// through a shared <see cref="DebugLogFileWriter"/>.
/// </summary>
public sealed class DebugFileLoggerProvider : ILoggerProvider
{
    /// <summary>The shared destination used by loggers created by this provider.</summary>
    private readonly DebugLogFileWriter _writer;

    /// <summary>
    /// Initializes a new instance of the <see cref="DebugFileLoggerProvider"/> class.
    /// </summary>
    /// <param name="writer">The non-null file writer used by every created logger.</param>
    public DebugFileLoggerProvider(DebugLogFileWriter writer)
    {
        _writer = writer;
    }

    /// <summary>
    /// Creates a logger for the specified category.
    /// </summary>
    /// <param name="categoryName">The category included in each emitted log entry.</param>
    /// <returns>A new logger backed by the provider's shared file writer.</returns>
    public ILogger CreateLogger(string categoryName)
    {
        return new DebugFileLogger(categoryName, _writer);
    }

    /// <summary>
    /// Releases provider resources.
    /// </summary>
    /// <remarks>
    /// The provider owns no disposable resources, so this method has no side effects.
    /// </remarks>
    public void Dispose()
    {
    }

    /// <summary>
    /// Implements the logging pipeline for one category.
    /// </summary>
    private sealed class DebugFileLogger : ILogger
    {
        /// <summary>The category written with each log entry.</summary>
        private readonly string _categoryName;

        /// <summary>The destination for formatted log entries.</summary>
        private readonly DebugLogFileWriter _writer;

        /// <summary>
        /// Initializes a new instance of the <see cref="DebugFileLogger"/> class.
        /// </summary>
        /// <param name="categoryName">The category to associate with emitted messages.</param>
        /// <param name="writer">The file writer that persists emitted messages.</param>
        public DebugFileLogger(string categoryName, DebugLogFileWriter writer)
        {
            _categoryName = categoryName;
            _writer = writer;
        }

        /// <summary>
        /// Begins a logical operation scope.
        /// </summary>
        /// <typeparam name="TState">The type of state attached to the scope.</typeparam>
        /// <param name="state">The non-null scope state. It is not inspected or retained.</param>
        /// <returns>
        /// Always <see langword="null"/> because this logger does not support external scopes.
        /// </returns>
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull
        {
            return null;
        }

        /// <summary>
        /// Determines whether the specified severity is written.
        /// </summary>
        /// <param name="logLevel">The severity to evaluate.</param>
        /// <returns>
        /// <see langword="true"/> for <see cref="LogLevel.Information"/> and higher severities;
        /// otherwise, <see langword="false"/>.
        /// </returns>
        public bool IsEnabled(LogLevel logLevel)
        {
            return logLevel >= LogLevel.Information;
        }

        /// <summary>
        /// Formats and writes an enabled log event.
        /// </summary>
        /// <typeparam name="TState">The type of the event state.</typeparam>
        /// <param name="logLevel">The event severity.</param>
        /// <param name="eventId">The event identifier; this implementation does not persist it.</param>
        /// <param name="state">The state passed to <paramref name="formatter"/>.</param>
        /// <param name="exception">
        /// The associated exception, or <see langword="null"/> when the event has no exception.
        /// </param>
        /// <param name="formatter">The callback used to produce the message text.</param>
        /// <remarks>
        /// Disabled events return without invoking <paramref name="formatter"/>. Enabled events
        /// append to the debug log and may rotate the existing file.
        /// </remarks>
        /// <exception cref="IOException">The log file cannot be written or rotated.</exception>
        /// <exception cref="UnauthorizedAccessException">The process cannot access the log path.</exception>
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