# ------------------------------------------------------------------------------
# --- Example script demonstrating figure_formatting.py functionality ---
# ------------------------------------------------------------------------------


import sys
import os
import numpy as np
from pathlib import Path
import matplotlib.pyplot as plt
from figure_formatting_kmn import setup_figure, save_figure


# Add current directory to path to import from same directory
# Works both when run as script (__file__ exists) and interactively (uses cwd)
try:
    current_dir = Path(__file__).parent
except NameError:
    # Interactive mode: use current working directory
    current_dir = Path(os.getcwd())

# Add to path if not already there
current_dir_str = str(current_dir)
if current_dir_str not in sys.path:
    sys.path.insert(0, current_dir_str)

# Create output directory
output_dir = current_dir / 'example_figures'
output_dir.mkdir(exist_ok=True)

# Generate sample data
x = np.linspace(0, 10, 100)
y = np.sin(x)

# ------------------------------------------------------------------------------
# Example 1: Default font (Helvetica, 7pt)
# ------------------------------------------------------------------------------
print("Creating example figure with default font settings...")

fig, ax = setup_figure(width_mm=80, height_mm=60, margins_mm=(0, 0, 0, 0))
ax.plot(x, y, linewidth=1)
ax.set_xlabel('X axis label')
ax.set_ylabel('Y axis label')
ax.set_title('Default font (Helvetica, 7pt)')
save_figure(fig, output_dir / 'example_default_font.svg')
plt.close(fig)

# ------------------------------------------------------------------------------
# Example 2: Multipanel figure (2x2 grid)
# ------------------------------------------------------------------------------
print("Creating multipanel figure (2x2 grid)...")

fig, axes = setup_figure(
    width_mm=150,
    height_mm=100,
    margins_mm=(0, 0, 0, 0),
    nrows=2,
    ncols=2,
    sharex=True,  # Share x-axis across subplots
    sharey=False  # Don't share y-axis
)

# Handle axes - can be single axis, list, or numpy array
if isinstance(axes, np.ndarray):
    axes_flat = axes.flatten()
elif isinstance(axes, (list, tuple)):
    axes_flat = axes
else:
    axes_flat = [axes]

# Plot different data in each subplot
for i, ax in enumerate(axes_flat):
    x_sub = np.linspace(0, 10, 100)
    y_sub = np.sin(x_sub + i * np.pi / 4)  # Different phase for each subplot
    ax.plot(x_sub, y_sub, linewidth=1)
    ax.set_xlabel('X axis label' if i >= 2 else '')
    ax.set_ylabel('Y axis label' if i % 2 == 0 else '')
    ax.set_title(f'Panel {i+1}')

save_figure(fig, output_dir / 'example_multipanel.svg')
plt.close(fig)

print(f"\nExample figure saved to: {output_dir}")
