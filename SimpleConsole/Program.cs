using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace SimpleConsole
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Setting MY_DYNAMIC_VAR using build worker API");

            using(WebClient wc = new WebClient())
            {
                wc.BaseAddress = Environment.GetEnvironmentVariable("APPVEYOR_API_URL");
                wc.Headers["Accept"] = "application/json";
                wc.Headers["Content-type"] = "application/json";

                var body = "{ \"name\": \"MY_DYNAMIC_VAR\", \"value\": \"I've been set inside a process!\" }";
                wc.UploadData("api/build/variables", "POST", Encoding.UTF8.GetBytes(body));
            }
        }
    }
}
