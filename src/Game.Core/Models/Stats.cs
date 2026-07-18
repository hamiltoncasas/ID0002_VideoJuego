namespace Game.Core.Models;

/// <summary>
/// Estadísticas base de cualquier entidad en el juego.
/// </summary>
public class Stats
{
    public int MaxHp { get; set; }
    public int CurrentHp { get; set; }
    public int Attack { get; set; }
    public int Defense { get; set; }
    public int MagicDefense { get; set; }
    public double AttackSpeed { get; set; } // ataques por segundo
    public double MoveSpeed { get; set; }  // velocidad de movimiento
    public double Range { get; set; }      // rango de ataque en unidades
    public double CritRate { get; set; }   // 0.0 a 1.0
    public double CritDamage { get; set; } // multiplicador (ej: 1.5 = 150%)
    public double DodgeRate { get; set; }  // 0.0 a 1.0

    public bool IsAlive => CurrentHp > 0;

    public Stats Clone()
    {
        return new Stats
        {
            MaxHp = MaxHp,
            CurrentHp = CurrentHp,
            Attack = Attack,
            Defense = Defense,
            MagicDefense = MagicDefense,
            AttackSpeed = AttackSpeed,
            MoveSpeed = MoveSpeed,
            Range = Range,
            CritRate = CritRate,
            CritDamage = CritDamage,
            DodgeRate = DodgeRate
        };
    }

    public static Stats operator +(Stats a, Stats b)
    {
        return new Stats
        {
            MaxHp = a.MaxHp + b.MaxHp,
            CurrentHp = a.CurrentHp + b.CurrentHp,
            Attack = a.Attack + b.Attack,
            Defense = a.Defense + b.Defense,
            MagicDefense = a.MagicDefense + b.MagicDefense,
            AttackSpeed = a.AttackSpeed + b.AttackSpeed,
            MoveSpeed = a.MoveSpeed + b.MoveSpeed,
            Range = a.Range + b.Range,
            CritRate = a.CritRate + b.CritRate,
            CritDamage = a.CritDamage + b.CritDamage,
            DodgeRate = a.DodgeRate + b.DodgeRate
        };
    }
}
