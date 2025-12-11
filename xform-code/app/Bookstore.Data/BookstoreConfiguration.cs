using System;
using System.Collections.Generic;
using Microsoft.Extensions.Configuration;

namespace BobsBookstoreClassic.Data
{
    public sealed class BookstoreConfiguration
    {
        private static readonly Lazy<BookstoreConfiguration> Lazy = new Lazy<BookstoreConfiguration>(() => new BookstoreConfiguration());

        private static BookstoreConfiguration Instance => Lazy.Value;

        private readonly Dictionary<string, string?> _appSettings = new Dictionary<string, string?>();
        private readonly Dictionary<string, string?> _connectionStrings = new Dictionary<string, string?>();
        private static IConfiguration? _configuration;

        private BookstoreConfiguration()
        {
        }

        public static void Initialize(IConfiguration configuration)
        {
            _configuration = configuration;
            
            // Load app settings
            var appSettingsSection = configuration.GetSection("AppSettings");
            foreach (var child in appSettingsSection.GetChildren())
            {
                Instance._appSettings[child.Key] = child.Value;
            }

            // Load connection strings
            var connectionStringsSection = configuration.GetSection("ConnectionStrings");
            foreach (var child in connectionStringsSection.GetChildren())
            {
                Instance._connectionStrings[child.Key] = child.Value;
            }

            // Override with environment variables
            foreach (var key in Instance._appSettings.Keys)
            {
                var envValue = Environment.GetEnvironmentVariable(key);
                if (envValue != null)
                {
                    Instance._appSettings[key] = envValue;
                }
            }
        }

        public static void AddSetting(string key, string value)
        {
            Instance._appSettings[key] = value;
        }

        public static string GetSetting(string key)
        {
            return Instance._appSettings.TryGetValue(key, out var value) ? value ?? string.Empty : string.Empty;
        }

        public static T GetSetting<T>(string key)
        {
            var value = Instance._appSettings[key];

            if (value == null)
                return default(T)!;

            return (T)Convert.ChangeType(value, typeof(T));
        }

        public static void AddConnectionString(string key, string value)
        {
            Instance._connectionStrings[key] = value;
        }

        public static string GetConnectionString(string key)
        {
            return Instance._connectionStrings.TryGetValue(key, out var value) ? value ?? string.Empty : string.Empty;
        }
    }
}