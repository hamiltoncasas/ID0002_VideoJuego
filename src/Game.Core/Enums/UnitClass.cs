namespace Game.Core.Enums;

/// <summary>
/// Clase de unidad de tropa. Define el counter system.
/// Infantería > Caballería > Arquero > Infantería
/// Mago > Infantería, Sanador aliado, Sin counter directo contra Asedio
/// Asedio > Edificios
/// </summary>
public enum UnitClass
{
    Infantry,    // cuerpo a cuerpo → counter: Cavalry
    Archer,      // ranged → counter: Infantry
    Cavalry,     // rápido → counter: Archer
    Mage,        // ranged mágico → counter: Infantry
    Healer,      // cura aliados
    Siege        // daño a edificios
}

/// <summary>
/// Tabla de ventajas entre clases de unidad.
/// </summary>
public static class UnitClassCounters
{
    private static readonly Dictionary<(UnitClass attacker, UnitClass defender), double> _advantages = new()
    {
        // Infantería counterea Caballería (1.5x daño)
        [(UnitClass.Infantry, UnitClass.Cavalry)] = 1.5,
        // Caballería counterea Arquero
        [(UnitClass.Cavalry, UnitClass.Archer)] = 1.5,
        // Arquero counterea Infantería
        [(UnitClass.Archer, UnitClass.Infantry)] = 1.5,
        // Mago counterea Infantería
        [(UnitClass.Mage, UnitClass.Infantry)] = 1.5,
        // Asedio counterea Building (se maneja aparte)
        // Desventajas (0.5x daño)
        [(UnitClass.Archer, UnitClass.Cavalry)] = 0.5,
        [(UnitClass.Infantry, UnitClass.Archer)] = 0.5,
        [(UnitClass.Cavalry, UnitClass.Infantry)] = 0.5,
        [(UnitClass.Infantry, UnitClass.Mage)] = 0.5,
    };

    /// <summary>
    /// Devuelve el multiplicador de daño por ventaja de clase.
    /// 1.0 = neutral, 1.5 = ventaja, 0.5 = desventaja.
    /// </summary>
    public static double GetMultiplier(UnitClass attacker, UnitClass defender)
    {
        return _advantages.GetValueOrDefault((attacker, defender), 1.0);
    }
}
