$j(document).ready(function() {
    $j("[href=/passes/checkout]").click(function(e) {
      if (!confirm("Do you really want to sign out?"))
          e.preventDefault();
    });
    // fade out the notifiers
    ease_out_notifier();

    
});