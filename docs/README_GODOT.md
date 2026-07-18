# Migración a Godot Engine - Magic Rush: Legado Muisca

## Resumen
Migración del proyecto de consola .NET 8.0 a Godot Engine 4.3 para obtener gráficos en tiempo real y preparar el juego para Android.

## Estado del proceso

### ✅ Completado
1. **Descarga e instalación de Godot 4.3**
   - Binario portable descargado de GitHub Releases
   - Funciona en modo headless y con renderizado OpenGL 3.3 via llvmpipe (software)
   - No requiere instalación, solo descompresión

2. **Creación del proyecto Godot**
   - `godot_project/project.godot` — configuración del motor
   - Renderizador: `gl_compatibility` (compatible con GPUs sin Vulkan)
   - Resolución: 1280x720

3. **Escenas creadas**
   - `scenes/main_menu.tscn` — Menú principal con título y botón jugar
   - `scenes/battle_scene.tscn` — Escena de batalla con 3 carriles

4. **Scripts GDScript**
   - `scripts/main_menu.gd` — Menú principal con screenshot automático
   - `scripts/battle_scene.gd` — Lógica de batalla completa

5. **Mecánicas implementadas en GDScript**
   - 3 carriles (TOP, MEDIO, BOT) con enemigos en cada uno
   - Héroe automático que ataca cada 0.8s
   - Enemigos que contraatacan
   - Sistema de críticos (20% chance, 2x daño)
   - Economía (oro, comida) con generación pasiva
   - Invocación de unidades [1-4]
   - Habilidad especial del héroe [4]
   - Pausa [ESPACIO]
   - Condiciones de victoria/derrota
   - Screenshots automáticos

### 📸 Capturas de pantalla

| Pantalla | Archivo |
|----------|---------|
| Menú principal | `screenshot_menu.png` |
| Batalla | `screenshot_battle.png` |

### 🖥️ Cómo ejecutar

```bash
# Desde la terminal (modo ventana)
cd godot_project
../Godot_v4.3-stable_linux.x86_64 --path .

# Para pruebas rápidas (genera screenshots automáticos)
../Godot_v4.3-stable_linux.x86_64 --path . --rendering-method gl_compatibility
```

### 🔄 Próximos pasos

1. **Assets visuales reales** — Reemplazar emojis y rectángulos por sprites/animaciones
2. **Sistema de partículas** — Efectos de habilidades
3. **Animaciones** — Movimiento de unidades por carriles
4. **UI completa** — Menú de héroes, inventario, habilidades
5. **Integración con backend C#** — Reutilizar la lógica de negocio del proyecto original
6. **Build Android** — Exportar a APK con las herramientas de Godot

## Requisitos del sistema
- OS: Linux, Windows, macOS
- GPU: OpenGL 3.3+ o Vulkan 1.0+
- RAM: 512 MB mínimo
- Almacenamiento: 200 MB (Godot) + 50 MB (proyecto)

## Notas técnicas
- Se usó GDScript en vez de C# para Godot porque:
  - GDScript es el lenguaje nativo de Godot, más rápido para prototipar
  - No requiere el build de .NET
  - Integración directa con el sistema de nodos/escenas
- El renderizado usa llvmpipe (software) en esta VM porque no hay GPU real
- En hardware real con GPU, Godot usa aceleración por hardware
