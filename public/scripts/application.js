(function() {
  var rank_counter = 5;
  $(".rank-data").hide();
  $("#showButton").click(function() {
    if (rank_counter < 1) return;
    var e = $(".rank-" + rank_counter);
    e.toggle();
    rank_counter--;
  });
})();
