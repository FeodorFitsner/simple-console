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
            Console.WriteLine("TestVar: " + Environment.GetEnvironmentVariable("TestVar"));
            Console.WriteLine("Set Console_Test_Process");
            Environment.SetEnvironmentVariable("Console_Test_Process", "Hello, process!");
            Console.WriteLine("Set Console_Test_Machine");
            Environment.SetEnvironmentVariable("Console_Test_Machine", "Hello, machine!", EnvironmentVariableTarget.Machine);
        }
    }
}
