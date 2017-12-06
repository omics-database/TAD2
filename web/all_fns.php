<?php
	require_once(".private/tad_display_fns.php");
	require_once(".private/tad_header.php");
	include("config.php");
	$date = shell_exec("date +%Y-%m-%d-%T");
	$explodedate = substr($date,0,-1);
?>
