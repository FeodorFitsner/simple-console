using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SimpleConsole
{
    class Program
    {
        static void Main(string[] args)
        {
            Environment.SetEnvironmentVariable("Console_Test_Process", "Hello, process!");
            Environment.SetEnvironmentVariable("Console_Test_Machine", "Hello, machine!", EnvironmentVariableTarget.Machine);
        }
    }
}
