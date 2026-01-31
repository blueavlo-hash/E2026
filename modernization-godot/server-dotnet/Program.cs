using System.Net;
using System.Net.Sockets;
using System.Text;

const int Port = 7777;
const int TickRate = 20;

var listener = new TcpListener(IPAddress.Loopback, Port);
listener.Start();

Console.WriteLine($"Server listening on 127.0.0.1:{Port}");

var tickIntervalMs = 1000 / TickRate;
var lastTick = Environment.TickCount64;

while (true)
{
    if (listener.Pending())
    {
        var client = await listener.AcceptTcpClientAsync();
        _ = Task.Run(async () =>
        {
            using var stream = client.GetStream();
            var welcome = Encoding.UTF8.GetBytes("WELCOME\n");
            await stream.WriteAsync(welcome);
            client.Close();
        });
    }

    var now = Environment.TickCount64;
    if (now - lastTick >= tickIntervalMs)
    {
        lastTick = now;
        // TODO: advance world simulation and broadcast snapshots
    }

    await Task.Delay(1);
}
