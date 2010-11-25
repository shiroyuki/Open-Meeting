$j(document).ready(function() {
    $j("[href=#signin]").click(function(e) {
      e.preventDefault();
      $("#header form").toggleClass("hidden");
    });
    $j("#signin [type=reset]").click(function(e) {
      $j("#header form").toggleClass("hidden");
    });
});