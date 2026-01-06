# ------------------------------------------------------------------------------------------------
# --- Example script demonstrating figure_formatting.R functionality ---
# ------------------------------------------------------------------------------------------------

# Source the figure formatting functions
# Works when run from the R/ directory or when figure_formatting.R is in the path
if (file.exists("figure_formatting.R")) {
  source("figure_formatting.R")
} else if (file.exists("R/figure_formatting.R")) {
  source("R/figure_formatting.R")
} else {
  stop("Could not find figure_formatting.R. Please ensure it's in the current directory or R/ subdirectory.")
}

# Load required packages
library(ggplot2)
library(cowplot)

# Create output directory
output_dir <- "example_figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Generate sample data
x <- seq(0, 10, length.out = 100)
y <- sin(x)
data <- data.frame(x = x, y = y)

# ------------------------------------------------------------------------------------------------
# Example 1: Single plot with default font settings
# ------------------------------------------------------------------------------------------------
cat("Creating example figure with default font settings...\n")

# set figure width and height
width_mm <- 80
height_mm <- 60

# Setup figure with default settings (Helvetica equivalent, 7pt)
fig_setup <- setup_figure(width_mm = width_mm, height_mm = height_mm)

# Create the plot
p1 <- ggplot(data, aes(x = x, y = y)) +
  geom_line(linewidth = 1) +
  labs(
    x = "X axis label",
    y = "Y axis label",
    title = "Default font (sans, 7pt)"
  ) +
  fig_setup$theme_obj

# Save the figure (dimensions come from fig_setup)
save_figure(p1, file.path(output_dir, "example_default_font.pdf"),
            width_mm = width_mm, height_mm = height_mm)

# Also save as SVG
save_figure(p1, file.path(output_dir, "example_default_font.svg"),
            width_mm = width_mm, height_mm = height_mm)

# ------------------------------------------------------------------------------------------------
# Example 2: Multipanel figure (2x2 grid) with shared y axis
# ------------------------------------------------------------------------------------------------
cat("Creating multipanel figure (2x2 grid)...\n")

# Setup for multipanel figure
width_mm <- 150
height_mm <- 100
fig_setup_multi <- setup_figure(
  width_mm = width_mm,
  height_mm = height_mm,
  nrows = 2,
  ncols = 2
)

# Create individual plots with different data
plots <- list()
for (i in 1:4) {
  phase <- (i - 1) * pi / 4
  y_sub <- sin(x + phase)
  data_sub <- data.frame(x = x, y = y_sub)
  
  p <- ggplot(data_sub, aes(x = x, y = y)) +
    geom_line(linewidth = 1) +
    labs(
      x = ifelse(i >= 3, "X axis label", ""),
      y = ifelse(i %% 2 == 1, "Y axis label", ""),
      title = paste("Panel", i)
    ) +
    fig_setup_multi$theme_obj
  
  plots[[i]] <- p
}

# Combine plots using cowplot's plot_grid
combined <- plot_grid(
  plotlist = plots,
  nrow = 2,
  ncol = 2,
  align = "hv"
)

# Save the combined figure (dimensions come from fig_setup_multi)
save_figure(combined, file.path(output_dir, "example_multipanel.svg"),
            width_mm = width_mm, height_mm = height_mm)
