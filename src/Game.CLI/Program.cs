using Game.CLI;
using Game.CLI.Demo;

namespace Game.CLI;

class Program
{
    static void Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;

        if (args.Length > 0 && args[0] == "--demo")
        {
            Console.CursorVisible = true;
            DemoRunner.Run();
            return;
        }

        Console.CursorVisible = false;
        var game = new GameController();
        game.Run();
        Console.CursorVisible = true;
    }
}
