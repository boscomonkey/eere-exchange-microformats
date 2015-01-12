$(document).ready(function ($) {
    $(".imgToggle").live("click", function () {
        $(this).parent().nextAll(".divToggleContent:first").slideToggle(400);

        var toggleImage = $(this)[0];
        if (toggleImage) {
            if (toggleImage.src.indexOf("collapse") !== -1) {
                toggleImage.src = toggleImage.src.replace("collapse", "expand");
                toggleImage.alt = "Expand";
            }
            else {
                toggleImage.src = toggleImage.src.replace("expand", "collapse");
                toggleImage.alt = "Collapse";
            }
        }
    });
});