<?php
if (!empty($_GET['file'])) {
  header('Content-disposition: attachment; filename="'.$_GET['name'].'"');
  header('Content-type: text/plain');
  readfile($_GET['file']);
//  shell_exec ("rm -f ".$_GET['file']); 
} else {
    return;
}
?>
