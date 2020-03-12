using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Text;
using Microsoft.AspNetCore.Blazor.Hosting;
using Microsoft.Extensions.DependencyInjection;
using TekHow.RabbitMq;

namespace docker7bday_demo
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebAssemblyHostBuilder.CreateDefault(args);
            builder.Services.AddSingleton<QueuingController>();
            builder.RootComponents.Add<App>("app");
            await builder.Build().RunAsync();
        }
    }
}
