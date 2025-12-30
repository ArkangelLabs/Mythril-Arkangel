// Override theme labels in ThemeSwitcher
$(document).ready(function() {
    // Wait for frappe to be fully loaded
    if (typeof frappe !== "undefined" && frappe.ui && frappe.ui.ThemeSwitcher) {
        const originalFetchThemes = frappe.ui.ThemeSwitcher.prototype.fetch_themes;
        frappe.ui.ThemeSwitcher.prototype.fetch_themes = function() {
            return new Promise((resolve) => {
                this.themes = [
                    {
                        name: "light",
                        label: __("Light"),
                        info: __("Light Theme"),
                    },
                    {
                        name: "dark",
                        label: __("Dark"),
                        info: __("Dark Theme"),
                    },
                    {
                        name: "automatic",
                        label: __("Automatic"),
                        info: __("Uses system theme"),
                    },
                ];
                resolve(this.themes);
            });
        };
    }
});
