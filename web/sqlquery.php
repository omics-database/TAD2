<?php				
	session_start();
	require_once('all_fns.php');
	tsqlquery(); 
	if (empty($_GET['quest'])) { $_GET['quest'] = ""; }
?>
<div class="menu">TransAtlasDB Database Query</div>
<?PHP
if ($_GET['quest'] == 'nosql') {
	$table = "nosql";
	@$fastbit=$_GET['fastbit'];
	if(!empty($_REQUEST['order'])) {
		$string = str_replace("'",'"',$_POST['search']);
		$_SESSION[$table]['select'] = str_replace("/\n/g", "", $string);
		$_SESSION[$table]['fastbit'] = $_POST['fastbit'];
	}
?>
<table width=100%><tr><td width=280pt>
		<div class="metamenu"><a href="sqlquery.php">Relational Database</a></div>
		<div class="metactive"><a href="sqlquery.php?quest=nosql">Non-relational Database</a></div>
	</td><td valign="top"><div class="dift">
		<table><tr><td>Perform NoSQL DML on the three data directories:</td><td>
	<ol type="i"><li> Gene expression information </li>
	<li> Gene Raw Counts information </li>
	<li> Variants information </li></ol></td></tr><tr><td colspan="2" align="right">
	<font size="2pt">For help with writing SQL select statements 
visit <a href="https://sdm.lbl.gov/fastbit/doc/ibisCommandLine.html#select" target="_blank">IBIS</a></font></td></tr></table>
	<!-- QUERY -->
	<form action="" method="post">
    <p class="pages"><span>Select NoSQL data folder: </span>
	<select name="fastbit" onchange="reload(this.form)">
		<option value="" selected disabled >Select FastBit Directory</option>
		<option value='gene-information'<?php if (@$fastbit=='gene-information') echo 'selected="selected"'; ?> >Gene Information</option>
		<option value='gene_count-information'<?php if (@$fastbit=='gene_count-information') echo 'selected="selected"'; ?> >Gene-counts Information</option>
		<option value='variant-information'<?php if (@$fastbit=='variant-information') echo 'selected="selected"'; ?> >Variant Information</option>
	</select></p>
		<p class="pages">
<?PHP
	if (!empty($_SESSION[$table]['select'])) {
		echo '<textarea name="search" rows="3" cols="80">'.$_SESSION[$table]["select"].'</textarea>';
	} else {
		echo '<textarea name="search" rows="3" cols="80" placeholder="Specify select syntax for NoSQL database ..."></textarea>';
	}
?>
	</p>
		<p class="pages">
    <input type="submit" name="order" value="Execute"/></p></div>
</form>
</div>
</td><td>
<?PHP
	if (@$fastbit == "gene-information") {
		echo '<table style="font-family:arial;border:1px solid grey;width:300px;color:#272a2c;padding-left:10pt;padding-right:10pt"><tr><th style="padding:2pt">Columns in <i>Gene Information</i> directory</th></tr><tr><td align="center">
sampleid, organism, tissue, chrom, start, stop, geneid, genename, coverage, tpm, fpkm, fpkmconfhigh, fpkmconflow, fpkmstatus
</td></tr></table>';
	} elseif (@$fastbit == "gene_count-information") {
		echo '<table style="font-family:arial;border:1px solid grey;width:300px;color:#272a2c;padding-left:10pt;padding-right:10pt"><tr><th style="padding:2pt">Columns in <i>Gene-Count Information</i> directory</th></tr><tr><td align="center">
sampleid, organism, tissue, genename, readcount
</td></tr></table>';
	} elseif (@$fastbit == "variant-information") {
		echo '<table style="font-family:arial;border:1px solid grey;width:300px;color:#272a2c;padding-left:10pt;padding-right:10pt"><tr><th style="padding:2pt">Columns in <i>Variant Information</i> directory</th></tr><tr><td align="center">
sampleid, organism, tissue, chrom, position, refallele, altallele, variantclass, zygosity, dbsnpvariant, source, consequence, geneid, genename, transcript, feature, genetype, aachange, codonchange, quality, proteinposition
</td></tr></table>';
	}
?>
</td></tr></table>
	
<?php
  	if ( !empty($db_conn) && (!empty($_POST['order']) || (!empty($_POST['search']) && !empty($_POST['fastbit'])) )) { //make sure an options is selected
		echo '<div class="menu">Output</div><div class="xtra">';
		$output = "OUTPUT/query_".$explodedate.".txt";
        //about_display($result, $result2);
		$pquery = "perl $basepath/tad-export.pl -w -nosql '".$_SESSION[$table]['fastbit']."' -query '".$_SESSION[$table]['select']."' -o $output";
		//print $pquery; 
		shell_exec($pquery);
		if (file_exists($output)){
			echo '<form action="" method="post">';
			echo '<p class="gened">Download the results below. ';
			$newbrowser = "results.php?file=$output&name=query.txt";
			echo '<input type="button" class="browser" value="Download Results" onclick="window.open(\''. $newbrowser .'\')"></p>';
			echo '</form>';
		
			// Get Tab delimted text from file
			$handle = fopen($output, "r");
			$contents = fread($handle, filesize($output)-1);
			fclose($handle);
			// Start building the HTML file
			print(tabs_to_table($contents));
		} else {
			echo '<center>No result based on search criteria.</center>';
		}
	}
} else {
	if(!empty($_REQUEST['order'])) {
		$_SESSION[$table]['select'] = $_POST['search'];
	}
	$table = "mysql";
?>	
<table width=100%><tr><td width=280pt>
		<div class="metactive"><a href="sqlquery.php">Relational Database</a></div>
		<div class="metamenu"><a href="sqlquery.php?quest=nosql">Non-relational Database</a></div>
	</td><td valign="top">
		<div class="dift">Perform SQL DML.<br>
	<!-- QUERY -->
	<form action="" method="post">
    <p class="pages">
<?php
	if (!empty($_SESSION[$table]['select'])) {
		echo '<textarea name="search" rows="3" cols="80">'.$_SESSION[$table]["select"].'</textarea>';
//<input type="text" size="80%" name="search" value="' . $_SESSION[$table]["select"] . '"\"/>';
	} else {
		echo '<textarea name="search" rows="3" cols="80" placeholder="Specify SQL syntax for MySQL database ..."></textarea>';
//'<input type="text" size="80%" name="search" placeholder="Specify SQL syntax for MySQL database"/>';
	}
?>
	</p>
		<p class="pages">
    <input type="submit" name="order" value="Execute"/></p></div>
</form>
</div>
</td></tr></table>
	
<?php
  	if ( !empty($db_conn) && (!empty($_POST['order']) || !empty($_POST['search'])) ) { //make sure an options is selected
		echo '<div class="menu">Output</div><div class="xtra">';
		echo '<form action="" method="post">';
		$result = $db_conn->query($_SESSION[$table]['select']);
		$result2 = "null";
		$output = "OUTPUT/query_".$explodedate.".txt";
        	$num_results = $result->num_rows;
		if ($num_results == 0) {
			echo '<center>No result based on search criteria.</center>';
		} else {
			echo '<input type="submit" name="downloadfiles" value="Download the results below"/>';
			about_display($result, $result2);
			$pquery = "perl $basepath/tad-export.pl -w -query '".$_SESSION[$table]['select']."' -o $output";
			if (isset($_POST['downloadfiles']) && !empty($_SESSION[$table]['select']) ){ 
				shell_exec($pquery);
	        	print("<script>location.href='results.php?file=$output&name=query.txt'</script>");
			}
		}
	}
} # end of relational database
	?>
<?php
  //$result ->free();
  $db_conn->close();
?>

</body>
</html>

