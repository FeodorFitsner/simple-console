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
            Console.WriteLine("Setting variables using build worker API");

            SetBuildVariable("GitVersion_Version", "1.0");
            SetBuildVariable("GitVersion_Branch", "master");
        }

        private static void SetBuildVariable(string name, string value)
        {
             using(WebClient wc = new WebClient())
            {
                wc.BaseAddress = Environment.GetEnvironmentVariable("APPVEYOR_API_URL");
                wc.Headers["Accept"] = "application/json";
                wc.Headers["Content-type"] = "application/json";

                var body = String.Format("{{ \"name\": \"{0}\", \"value\": \"{1}\" }}", name, value);
                wc.UploadData("api/build/variables", "POST", Encoding.UTF8.GetBytes(body));
            }
        }
    }
}
