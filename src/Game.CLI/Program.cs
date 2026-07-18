using Game.CLI;
using Game.Core.Enums;
using Game.Core.Events;
using Game.Core.Models;
using Game.Data.Config;
using Game.Data.Serialization;
using Game.Engine.Combat;
using Game.Engine.Simulation;

namespace Game.CLI;

class Program
{
    static void Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        Console.CursorVisible = false;

        var game = new GameController();
        game.Run();

        Console.CursorVisible = true;
    }
}
