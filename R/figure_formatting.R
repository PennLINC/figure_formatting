# ------------------------------------------------------------------------------------------------
# --- Figure formatting utilities ---
# ------------------------------------------------------------------------------------------------

# This script contains utilities for formatting figures at an exact physical size (mm) 
# with consistent styling (font size, font type, line width, etc.).
# The specified size includes all plot elements (axes, labels, ticks, etc.), not just the plot area.

# ------------------------------------------------------------------------------------------------
# --- Load packages ---
# ------------------------------------------------------------------------------------------------
library(ggplot2)
library(cowplot)
library(grid)

# ------------------------------------------------------------------------------------------------
# --- Helper functions ---
# ------------------------------------------------------------------------------------------------

# Convert millimeters to inches (for internal use)
mm_to_in <- function(mm) {
  return(mm / 25.4)
}

# Check which font is available from a list of font names
# Returns the first available font and prints which one is being used
# Automatically imports fonts using extrafont if needed
.check_font_availability <- function(font_list) {
  # Convert single string to list if needed
  if (is.character(font_list) && length(font_list) == 1) {
    font_list <- list(font_list)
  } else if (is.character(font_list)) {
    font_list <- as.list(font_list)
  }
  
  available_font <- NULL
  
  # Check if extrafont package is available (needed to import fonts into R)
  extrafont_available <- requireNamespace("extrafont", quietly = TRUE)
  
  if (!extrafont_available) {
    cat("[figformat] Installing extrafont package to manage fonts...\n")
    tryCatch({
      install.packages("extrafont", repos = "https://cran.r-project.org", quiet = TRUE)
      extrafont_available <- requireNamespace("extrafont", quietly = TRUE)
      if (extrafont_available) {
        cat("[figformat] extrafont package installed successfully.\n")
      }
    }, error = function(e) {
      cat("[figformat] WARNING: Could not install extrafont package automatically.\n")
      cat("[figformat] Please install manually: install.packages('extrafont')\n")
    })
  }
  
  # Try to load fonts using extrafont
  if (extrafont_available) {
    tryCatch({
      # Try to load fonts (this will fail if fonts haven't been imported)
      extrafont::loadfonts(quiet = TRUE)
    }, error = function(e) {
      # Fonts haven't been imported yet, try to import them
      cat("[figformat] Fonts not yet imported. Importing fonts from system (this may take a minute)...\n")
      tryCatch({
        extrafont::font_import(prompt = FALSE, pattern = NULL)
        extrafont::loadfonts(quiet = TRUE)
        cat("[figformat] Font import complete.\n")
      }, error = function(e2) {
        cat("[figformat] WARNING: Could not import fonts automatically.\n")
        cat("[figformat] You may need to run: extrafont::font_import() manually.\n")
      })
    })
    
    # Check which fonts are available in extrafont
    tryCatch({
      extrafont_fonts <- extrafont::fonts()
      for (font_name in font_list) {
        if (any(tolower(extrafont_fonts) == tolower(font_name), na.rm = TRUE)) {
          available_font <- font_name
          break
        }
      }
    }, error = function(e) {
      # If extrafont check fails, continue to systemfonts
    })
  }
  
  # Try using systemfonts package if available (for checking system fonts)
  if (is.null(available_font) && requireNamespace("systemfonts", quietly = TRUE)) {
    tryCatch({
      system_fonts <- systemfonts::system_fonts()
      for (font_name in font_list) {
        # Check if font exists in system (case-insensitive)
        font_found <- any(tolower(system_fonts$family) == tolower(font_name), na.rm = TRUE)
        if (font_found) {
          # Font exists in system, but may not be imported to R yet
          # Try to import it if extrafont is available
          if (extrafont_available) {
            tryCatch({
              extrafont_fonts <- extrafont::fonts()
              if (!any(tolower(extrafont_fonts) == tolower(font_name), na.rm = TRUE)) {
                cat("[figformat] Font", font_name, "found in system but not imported to R.\n")
                cat("[figformat] Attempting to import...\n")
                # Try to import just this font (more efficient)
                extrafont::font_import(prompt = FALSE, pattern = font_name)
                extrafont::loadfonts(quiet = TRUE)
                # Check again if it's now available
                extrafont_fonts <- extrafont::fonts()
                if (any(tolower(extrafont_fonts) == tolower(font_name), na.rm = TRUE)) {
                  cat("[figformat] Font", font_name, "successfully imported.\n")
                }
              }
            }, error = function(e) {
              # Import failed, but we can still try to use the font
              # (font exists in system, so we'll use it anyway)
            })
          }
          # Font found in system, use it
          available_font <- font_name
          break
        }
      }
    }, error = function(e) {
      # If systemfonts fails, continue to final fallback
    })
  }
  
  # Final fallback: use the first font in the list
  # R/ggplot2 will attempt to use it, and will fall back to default if not available
  if (is.null(available_font)) {
    available_font <- font_list[[1]]
    cat("[figformat] Using font:", available_font, 
        "(availability not verified - R will use fallback if font not found)\n")
  } else {
    cat("[figformat] Using font:", available_font, "\n")
  }
  
  return(available_font)
}

# Apply theme settings for consistent figure styling
# This is an internal function that sets up ggplot2 theme parameters
.apply_theme <- function(
  base_pt = 7,
  label_pt = 7,
  title_pt = 7,
  font_family = "sans",
  font_type = NULL,
  font_face = "plain",
  axes_linewidth = 0.8,
  line_width = 1
) {
  # Determine the actual font family to use
  # If font_family is "sans" and font_type is not specified, default to Arial
  if (font_family == "sans" && is.null(font_type)) {
    font_type <- "Arial"
  }
  
  # If font_type is specified, check availability and use it
  if (!is.null(font_type)) {
    # Check which font is available (function handles conversion to list)
    selected_font <- .check_font_availability(font_type)
    
    # Use the selected font as the family
    font_family_actual <- selected_font
  } else {
    font_family_actual <- font_family
  }
  
  # Create base theme with minimal margins
  # The total figure size (specified in setup_figure) includes all plot elements
  # including axes, labels, ticks, and titles. The plot.margin controls spacing
  # within the figure, so we set it to minimal values to maximize plot area while
  # ensuring labels fit within the specified total size.
  theme_base <- theme_classic() +
    theme(
      # Font settings
      text = element_text(family = font_family_actual, size = base_pt, face = font_face),
      axis.text = element_text(size = base_pt, color = "black"),
      axis.title = element_text(size = label_pt, color = "black"),
      plot.title = element_text(size = title_pt, color = "black", hjust = 0.5),
      legend.text = element_text(size = base_pt, color = "black"),
      legend.title = element_text(size = base_pt, color = "black"),
      
      # Line widths
      axis.line = element_line(linewidth = axes_linewidth, color = "black"),
      axis.ticks = element_line(linewidth = axes_linewidth, color = "black"),
      
      # Minimal margins - labels and ticks are part of the total figure size
      # These small margins ensure proper spacing without adding extra size
      plot.margin = margin(1, 1, 1, 1, "mm"),
      
      # Remove background
      panel.background = element_blank(),
      plot.background = element_blank()
    )
  
  return(theme_base)
}

# ------------------------------------------------------------------------------------------------
# --- Main functions ---
# ------------------------------------------------------------------------------------------------

#' Setup a figure with exact physical size and consistent styling
#'
#' Create a ggplot2 figure with precise physical dimensions in millimeters.
#' The specified size includes all plot elements (axes, labels, ticks, etc.),
#' not just the plot area. This function applies consistent styling (fonts, line widths)
#' and can create single plots or prepare for multipanel arrangements.
#'
#' @param width_mm Numeric. Figure width in millimeters (includes all elements).
#' @param height_mm Numeric. Figure height in millimeters (includes all elements).
#' @param base_pt Integer. Font size in points for tick labels, legend text, and other base elements. Default: 7.
#' @param label_pt Integer. Font size in points for axis labels (xlabel, ylabel). Default: 7.
#' @param title_pt Integer. Font size in points for plot titles. Default: 7.
#' @param font_family Character. Font family. Common values: "sans", "serif", "mono". Default: "sans".
#' @param font_type Character or list of character. Specific font name(s) to use. 
#'   If a list, the first available font will be selected. 
#'   When font_family="sans", defaults to "Arial" if not specified.
#'   Examples: "Arial", "Helvetica", c("Arial", "Helvetica", "sans-serif").
#' @param font_face Character. Font face: "plain", "bold", "italic", "bold.italic". Default: "plain".
#' @param axes_linewidth Numeric. Line width in points for axes (spines, ticks). Default: 0.8.
#' @param line_width Numeric. Default line width in points for plot lines. Default: 1.
#' @param nrows Integer. Number of rows for subplot grid. Default: 1.
#' @param ncols Integer. Number of columns for subplot grid. Default: 1.
#'
#' @return A list containing:
#'   - `theme_obj`: The ggplot2 theme object to apply to plots
#'   - `width_mm`: The figure width in mm
#'   - `height_mm`: The figure height in mm
#'   - `nrows`: Number of rows
#'   - `ncols`: Number of columns
#'
#' @examples
#' # Single plot with default font (Arial for sans-serif)
#' fig_setup <- setup_figure(width_mm = 80, height_mm = 60)
#' p <- ggplot(mtcars, aes(x = mpg, y = hp)) + 
#'   geom_point() + 
#'   fig_setup$theme_obj
#' save_figure(p, "plot.pdf", width_mm = 80, height_mm = 60)
#'
#' # Single plot with specific font
#' fig_setup <- setup_figure(width_mm = 80, height_mm = 60, font_type = "Helvetica")
#' p <- ggplot(mtcars, aes(x = mpg, y = hp)) + 
#'   geom_point() + 
#'   fig_setup$theme_obj
#' save_figure(p, "plot.pdf", width_mm = 80, height_mm = 60)
#'
#' # Single plot with font list (uses first available)
#' fig_setup <- setup_figure(width_mm = 80, height_mm = 60, 
#'                           font_type = c("Arial", "Helvetica", "sans-serif"))
#' p <- ggplot(mtcars, aes(x = mpg, y = hp)) + 
#'   geom_point() + 
#'   fig_setup$theme_obj
#' save_figure(p, "plot.pdf", width_mm = 80, height_mm = 60)
#'
#' # For multipanel figures, create individual plots and combine with cowplot's plot_grid
#' fig_setup <- setup_figure(width_mm = 150, height_mm = 100, nrows = 2, ncols = 2)
#' p1 <- ggplot(mtcars, aes(x = mpg, y = hp)) + geom_point() + fig_setup$theme_obj
#' p2 <- ggplot(mtcars, aes(x = mpg, y = wt)) + geom_point() + fig_setup$theme_obj
#' p3 <- ggplot(mtcars, aes(x = mpg, y = disp)) + geom_point() + fig_setup$theme_obj
#' p4 <- ggplot(mtcars, aes(x = mpg, y = drat)) + geom_point() + fig_setup$theme_obj
#' combined <- plot_grid(p1, p2, p3, p4, nrow = 2, ncol = 2)
#' save_figure(combined, "multipanel.pdf", width_mm = 150, height_mm = 100)
#'
#' @export
setup_figure <- function(
  width_mm,
  height_mm,
  base_pt = 7,
  label_pt = 7,
  title_pt = 7,
  font_family = "sans",
  font_type = NULL,
  font_face = "plain",
  axes_linewidth = 0.8,
  line_width = 1,
  nrows = 1,
  ncols = 1
) {
  # Apply theme settings
  theme_obj <- .apply_theme(
    base_pt = base_pt,
    label_pt = label_pt,
    title_pt = title_pt,
    font_family = font_family,
    font_type = font_type,
    font_face = font_face,
    axes_linewidth = axes_linewidth,
    line_width = line_width
  )
  
  # Return setup information
  return(list(
    theme_obj = theme_obj,
    width_mm = width_mm,
    height_mm = height_mm,
    nrows = nrows,
    ncols = ncols
  ))
}

#' Save a figure with exact physical size
#'
#' Save a ggplot2 plot or cowplot grid object to a file with exact physical dimensions.
#' The saved figure will match the specified dimensions exactly. The total size includes
#' all plot elements: the plot area, axes, labels, ticks, titles, and legends.
#' 
#' When saving with ggsave() using units="mm", the specified dimensions set the total
#' device size, and the plot (including all its elements) is rendered within that size.
#'
#' @param plot A ggplot2 plot object or cowplot grid object (from plot_grid, etc.).
#' @param path Character. File path for saving. Extension determines format (pdf, svg, png, etc.).
#' @param width_mm Numeric. Figure width in millimeters. If NULL, uses the plot's stored width.
#' @param height_mm Numeric. Figure height in millimeters. If NULL, uses the plot's stored height.
#' @param dpi Numeric. Resolution for raster formats (png, jpeg, etc.). Default: 300.
#' @param device Character. Graphics device. If NULL, inferred from file extension. 
#'   Options: "pdf", "svg", "png", "jpeg", "tiff", etc.
#'
#' @return Invisibly returns the plot object.
#'
#' @examples
#' fig_setup <- setup_figure(width_mm = 80, height_mm = 60)
#' p <- ggplot(mtcars, aes(x = mpg, y = hp)) + 
#'   geom_point() + 
#'   fig_setup$theme_obj
#' save_figure(p, "plot.pdf", width_mm = 80, height_mm = 60)
#'
#' @export
save_figure <- function(
  plot,
  path,
  width_mm = NULL,
  height_mm = NULL,
  dpi = 300,
  device = NULL
) {
  # If width/height not specified, try to get from plot attributes
  if (is.null(width_mm) && !is.null(attr(plot, "width_mm"))) {
    width_mm <- attr(plot, "width_mm")
  }
  if (is.null(height_mm) && !is.null(attr(plot, "height_mm"))) {
    height_mm <- attr(plot, "height_mm")
  }
  
  # If still NULL, error
  if (is.null(width_mm) || is.null(height_mm)) {
    stop("width_mm and height_mm must be specified")
  }
  
  # Determine device from extension if not specified
  if (is.null(device)) {
    ext <- tolower(tools::file_ext(path))
    device_map <- list(
      "pdf" = "pdf",
      "svg" = "svg",
      "png" = "png",
      "jpg" = "jpeg",
      "jpeg" = "jpeg",
      "tif" = "tiff",
      "tiff" = "tiff"
    )
    device <- device_map[[ext]]
    if (is.null(device)) {
      device <- ext  # fallback to extension
    }
  }
  
  # Save the plot
  # For vector formats (pdf, svg), use mm directly
  # ggsave with units="mm" sets the total device size, and the plot (including
  # all elements like labels, ticks, etc.) is rendered within that size
  if (device %in% c("pdf", "svg")) {
    ggsave(
      filename = path,
      plot = plot,
      width = width_mm,
      height = height_mm,
      units = "mm",
      device = device,
      dpi = dpi
    )
  } else {
    # For raster formats, convert mm to inches then to pixels
    width_in <- mm_to_in(width_mm)
    height_in <- mm_to_in(height_mm)
    ggsave(
      filename = path,
      plot = plot,
      width = width_in,
      height = height_in,
      units = "in",
      device = device,
      dpi = dpi
    )
  }
  
  invisible(plot)
}

