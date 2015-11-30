using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

namespace SocketTest
{
    class Program
    {
        static void Main(string[] args)
        {
            for (int i = 0; i < 10; ++i)
            {
                const AddressFamily family = AddressFamily.InterNetwork;
                const SocketType socket = SocketType.Stream;
                const ProtocolType protocol = ProtocolType.Tcp;
                using (var client = new Socket(family, socket, protocol))
                using (var server = new Socket(family, socket, protocol))
                {
                    client.ReceiveTimeout = 10000;
                    server.ExclusiveAddressUse = true;
                    server.Bind(new IPEndPoint(IPAddress.Loopback, 60310));
                    bool isConnected = false;
                    server.Listen(1);
                    server.BeginAccept(ar =>
                    {
                        Console.WriteLine("BeginAccept handler");
                        var serverCon = server.EndAccept(ar);
                        Console.WriteLine("EndAccept called");
                        isConnected = true;
                        serverCon.Send(new byte[256]);
                    }, null);
                    try
                    {
                        client.Connect(server.LocalEndPoint);
                        Console.WriteLine("socket.Connected: {0} to {1}", client.Connected, client.RemoteEndPoint);
                    }
                    catch (Exception e)
                    {
                        throw new Exception(string.Format("Connect failed: {0}", e.Message), e);
                    }
                    client.Send(new byte[256]);
                    try
                    {
                        int length = client.Receive(new byte[256]);
                        //length.Should().Be(256);
                        Console.WriteLine("Length: " + length.ToString());
                    }
                    catch (Exception e)
                    {
                        throw new Exception(string.Format("Receive #{0} failed (Connected: {1}): {2}",
                                                          i,
                                                          isConnected,
                                                          e.Message),
                                            e);
                    }
                }
            }
        }
    }
}
