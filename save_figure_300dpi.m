function save_figure_300dpi(fig, filename)
%SAVE_FIGURE_300DPI Save a MATLAB figure with a compatibility fallback.

try
    exportgraphics(fig, filename, 'Resolution', 300);
catch
    set(fig, 'PaperPositionMode', 'auto');
    print(fig, filename, '-dpng', '-r300');
end

end
