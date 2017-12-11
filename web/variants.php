<?php				
	session_start();
	require_once('all_fns.php');
	if (empty($_GET['quest'])) { $_GET['quest'] = ""; }
	if (empty($chromosomes)) {$chromosomes = "";}
	if (empty($samples)) {$samples = "";}
	if (empty($tissues)) {$tissues = "";}
	if (empty($_POST['sample'])) { $_POST['sample'] = ""; }
	if (empty($_POST['organism'])) { $_POST['organism'] = ""; }
	if (empty($_POST['chromosome'])) { $_POST['chromosome'] = ""; }
?>
<?PHP
	@$species=$_GET['organism'];
	$table = "vw_sampleinfo";
	$Vartable = "VarResult";
	$Varstats = "VarStatus";

if($_GET['quest'] == 'summary') {
	tvarisum();		
?>
		<div class="menu">TransAtlasDB Variant Distribution</div>
			<table width=100%><tr><td width="280pt">
				<div class="metactive"><a href="variants.php?quest=summary">Variants Distribution</a></div>
				<div class="metamenu"><a href="variants.php">Gene - Associated Variants</a></div>
				<div class="metamenu"><a href="variants.php?quest=chrom">Variants - Chromosomal position </a></div>
			</td><td>
				<div class="dift"><p> View variants chromosomal distribution across samples.</p>
<?php
	if(isset($species)){
		$query="SELECT sampleid FROM $table where organism='$species' and totalvariants is not null order by sampleid";
		$query2="SELECT distinct chrom FROM $Vartable where sampleid = (select distinct sampleid from $table where organism='$species' and totalvariants is not null order by sampleid limit 1) order by length(chrom), chrom"; 
	}else {
		$query ="SELECT sampleid FROM $table where organism is null and totalvariants is not null order by sampleid";
		$query2="SELECT distinct chrom FROM $Vartable where sampleid = (select distinct sampleid from $table where organism is null and totalvariants is not null order by sampleid limit 1) order by length(chrom), chrom";
	}

	if (!empty($_REQUEST['salute'])) {
		$_SESSION[$Vartable]['sample'] = $_POST['sample'];
		$_SESSION[$Vartable]['chromosome'] = $_POST['chromosome'];
		$_SESSION[$Vartable]['organism'] = $_POST['organism'];
	}
?>

	<div class="question">
	<form action="" method="post">
    <p class="pages"><span>Select Organism: </span>
    <select name="organism" onchange="reload(this.form)">
		<option value="" selected disabled >Select Organism</option>
		<?php
			foreach ($db_conn->query("select distinct organism from $table") as $row) {
				if($row["organism"]==@$species){ echo "<option selected value='$row[organism]'>$row[organism]</option><br>"; }
				else { echo '<option value="'.$row['organism'].'">'. $row['organism'].'</option>';}
			}
		?>
	</select></p>
	
	<table><tr><td><p class="pages"><span>Samples: </span>
	<select name="sample[]" id="sample" size=3 multiple="multiple">
		<option value="" selected disabled >Select Sample(s)</option>
		<?php
			foreach ($db_conn->query($query) as $row) {
				echo "<option value='$row[sampleid]'>$row[sampleid]</option>";
			}
		?>
	</select></td><td>
	
	<p class="pages"><span>Chromosomes: </span>
	<select name="chromosome[]" id="chromosome" size=3 multiple="multiple">
		<option value="" selected disabled >Select Chromosome(s)</option>
		<?php
			foreach ($db_conn->query($query2) as $row) {
				echo "<option value='$row[chrom]'>$row[chrom]</option>";
			}
		?>
	</select></p></td></tr></table>
<center><input type="submit" name="salute" value="View Results"></center>
</form>
</div>
  </td></tr></table>

<?php
	if (!empty($_POST['salute'])) {
		echo '<div class="menu">Results</div><div class="xtra">';
		$queryforoutput = "yes";
		$output = "OUTPUT/chrvar_".$explodedate.".txt";
		if (!empty($_POST['sample'])) { foreach ($_POST["sample"] as $sample){ $samples .= $sample. ","; } $samples = rtrim($samples,","); }
		if (!empty($_POST['chromosome'])) { foreach ($_POST["chromosome"] as $chromosome){ $chromosomes .= $chromosome. ","; } $chromosomes = rtrim($chromosomes,","); }
		
		if ((!empty($_POST['sample'])) && (!empty($_POST['organism'])) && (!empty($_POST['chromosome']))) {          
			$pquery = "perl $basepath/tad-export.pl -w -db2data -chrvar -species '$_POST[organism]' --chromosome '$chromosomes' --samples '$samples' -o $output";
		} elseif ((!empty($_POST['sample'])) && (!empty($_POST['organism']))) {          
			$pquery = "perl $basepath/tad-export.pl -w -db2data -chrvar -species '$_POST[organism]' --samples '$samples' -o $output";
		} elseif ((!empty($_POST['chromosome'])) && (!empty($_POST['organism']))) {          
			$pquery = "perl $basepath/tad-export.pl -w -db2data -chrvar -species '$_POST[organism]' --chromosome '$chromosomes' -o $output";
		} elseif (!empty($_POST['organism'])) {          
			$pquery = "perl $basepath/tad-export.pl -w -db2data -chrvar -species '$_POST[organism]' -o $output";
		}else {
			$queryforoutput = "no";
			echo "<center>Forgot something ?</center>";
		}
		//print $pquery;
		if ($queryforoutput == "yes") {
			shell_exec($pquery);
			if (file_exists($output)){
				echo '<form action="" method="post">';
				echo '<p class="gened">Download the results below. ';
				$newbrowser = "results.php?file=$output&name=chromosomevariants.txt";
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
	}
?>
	</div>
<?php
	$db_conn->close();
} elseif ($_GET['quest'] == 'chrom') {
	tvarichrom();
?>
	<div class="menu">TransAtlasDB Chromosome - Variant Information</div>
		<table width=100%><tr><td width="280pt">
			<div class="metamenu"><a href="variants.php?quest=summary">Variants Distribution</a></div>
			<div class="metamenu"><a href="variants.php">Gene - Associated Variants</a></div>
			<div class="metactive"><a href="variants.php?quest=chrom">Variants - Chromosomal position </a></div>
		</td><td>
			<div class="dift"><p> View variants chromosomal distribution across samples.</p>
<?php
	if(isset($species)){
		$query = "SELECT distinct chrom FROM $Vartable where sampleid = (select distinct sampleid from $table where organism='$species' and totalvariants is not null order by sampleid limit 1) order by length(chrom), chrom"; 
	}else {
		$query ="SELECT distinct chrom FROM $Vartable where sampleid = (select distinct sampleid from $table where organism is null and totalvariants is not null order by sampleid limit 1) order by length(chrom), chrom";
	}

	if (!empty($_REQUEST['salute'])) {
		$_SESSION[$Vartable]['region'] = $_POST['region'];
		$_SESSION[$Vartable]['organism'] = $_POST['organism'];
	}
?>

  <div class="question">
  <form action="" method="post">
    <p class="pages"><span>Select Organism: </span>
    <select name="organism" onchange="reload(this.form)">
		<option value="" selected disabled >Select Organism</option>
		<?php
			foreach ($db_conn->query("select distinct organism from $table") as $row) {
				if($row["organism"]==@$species){ echo "<option selected value='$row[organism]'>$row[organism]</option><br>"; }
				else { echo '<option value="'.$row['organism'].'">'. $row['organism'].'</option>';}
			}
		?>
	</select></p>
	
	<p class="pages"><span>Chromosomes: </span>
	<select name="chromosome[]" id="chromosome" size=3 multiple="multiple">
		<option value="" selected disabled >Select Chromosome(s)</option>
		<?php
			foreach ($db_conn->query($query) as $row) {
				echo "<option value='$row[chrom]'>$row[chrom]</option>";
			}
		?>
	</select></p>
	
	<p class="pages"><span>Region: </span>
	<?php
		if (!empty($_SESSION[$Vartable]['region'])) {
		  echo '<input type="text" name="region" id="genename" size="35" value="' .$_SESSION[$Vartable]['region']. '"/></p>';
		} else {
		  echo '<input type="text" name="region" id="genename" size="35" placeholder="Region of interest (eg: 10000-500000)" /></p>';
		}
	?>
	
<center><input type="submit" name="salute" value="View Results"></center>
</form>
</div>
  </td></tr></table>

<?php
	if (!empty($_POST['salute'])) {
		echo '<div class="menu">Results</div><div class="xtra">';
		$queryforoutput = "yes";
		$output = "OUTPUT/variants_".$explodedate.".txt";
		$vcfoutput = "OUTPUT/variants_".$explodedate.".vcf";
		if (!empty($_POST['sample'])) { foreach ($_POST["sample"] as $sample){ $samples .= $sample. ","; } $samples = rtrim($samples,","); }
		if (!empty($_POST['chromosome'])) { foreach ($_POST["chromosome"] as $chromosome){ $chromosomes .= $chromosome. ","; } $chromosomes = rtrim($chromosomes,","); }
		$counter = count($_POST['chromosome']);
		if ((!empty($_POST['region'])) && (!empty($_POST['organism'])) && (!empty($_POST['chromosome']))) {
			if ($counter < 2) {
				$pquery = "perl $basepath/tad-export.pl -w -db2data -varanno -species '$_POST[organism]' --chromosome '$chromosomes' --region $_POST[region] -o $output";
			} else {
				$pquery = "perl $basepath/tad-export.pl -w -db2data -varanno -species '$_POST[organism]' --chromosome '$chromosomes' -o $output";
			}
		} elseif ((!empty($_POST['chromosome'])) && (!empty($_POST['organism']))) {          
			$pquery = "perl $basepath/tad-export.pl -w -db2data -varanno -species '$_POST[organism]' --chromosome '$chromosomes' -o $output";
		} elseif (!empty($_POST['organism'])) {          
			$pquery = "perl $basepath/tad-export.pl -w -db2data -varanno -species '$_POST[organism]' -o $output";
		}else {
			$queryforoutput = "no";
			echo "<center>Forgot something ?</center>";
		}
		//print $pquery;
		if ($queryforoutput == "yes") {
			shell_exec($pquery);
			if (file_exists($output)){
				echo '<form action="" method="post">';
				echo '<p class="gened">Download the results below. ';
				$newbrowser = "results.php?file=$output&name=chromosomevariants.txt";
				$vcfprocess = $pquery." -vcf";
				shell_exec($vcfprocess);
				$vcfbrowser = "results.php?file=$vcfoutput&name=chromosomevariants.vcf";
				echo '<input type="button" class="browser" value="Download Results" onclick="window.open(\''. $newbrowser .'\')">
				<input type="button" class="browser" value="Generate VCF" onclick="window.open(\''.$vcfbrowser.'\')";></p>';
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
	}
?>
  </div>
<?php
	$db_conn->close();
} else {
	tvariants();
?>
	<div class="menu">TransAtlasDB Gene - Variant Information</div>
		<table width=100%><tr><td width="280pt">
			<div class="metamenu"><a href="variants.php?quest=summary">Variants Distribution</a></div>
			<div class="metactive"><a href="variants.php">Gene - Associated Variants</a></div>
			<div class="metamenu"><a href="variants.php?quest=chrom">Variants - Chromosomal position </a></div>
		</td><td>
			<div class="dift"><p> View variants based on a specific gene of interest.</p>

<?php
	if(isset($species)){
		$query="SELECT DISTINCT tissue FROM $table where organism='$species' order by tissue"; 
	}else{ $query ="SELECT DISTINCT tissue FROM $table order by tissue"; }

	if (!empty($_REQUEST['salute'])) {
		$_SESSION[$Varstats]['organism'] = $_POST['organism'];
		$_SESSION[$Varstats]['search'] = $_POST['search'];
	}
?>

  <div class="question">
  <form action="" method="post">
    <p class="pages"><span>Select Organism: </span>
    <select name="organism" onchange="reload(this.form)">
		<option value="" selected disabled >Select Organism</option>
		<?php
			foreach ($db_conn->query("select distinct organism from $table") as $row) {
				if($row["organism"]==@$species){ echo "<option selected value='$row[organism]'>$row[organism]</option><br>"; }
				else { echo '<option value="'.$row['organism'].'">'. $row['organism'].'</option>';}
			}
		?>
	</select></p>

    <p class="pages"><span>Specify your gene name: </span>
	<?php
		if (!empty($_SESSION[$Varstats]['search'])) {
		  echo '<input type="text" name="search" id="genename" size="35" value="' .$_SESSION[$Varstats]['search']. '"/></p>';
		} else {
		  echo '<input type="text" name="search" id="genename" size="35" placeholder="Enter Gene Name(s)" /></p>';
		}
	?><br><br>
<center><input type="submit" name="salute" value="View Results"></center>
</form>
</div>
  </td></tr></table>

<?php
	if (!empty($_POST['salute'])) {
		echo '<div class="menu">Results</div><div class="xtra">';
		if ((!empty($_POST['organism'])) && (!empty($_POST['search']))) {          
			$output = "OUTPUT/variants_".$explodedate.".txt";
			$genenames = rtrim($_POST['search'],",");
			$pquery = "perl $basepath/tad-export.pl -w -db2data -varanno -species '$_POST[organism]' --gene '".strtoupper("$genenames")."' -o $output";
			//print $pquery;
			shell_exec($pquery);
			if (file_exists($output)){
				echo '<form action="" method="post">';
				echo '<p class="gened">Download the results below. ';
				$newbrowser = "results.php?file=$output&name=genevariant.txt";
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
		} else {
			echo "<center>Forgot something ?</center>";
		}
	}
?>
	</div>
<?php
	$db_conn->close(); 	
}
?>

</body>
</html>
