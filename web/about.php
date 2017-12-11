<?php				
	session_start();
	require_once('all_fns.php');
	tmetadata(); 
	if (empty($_GET['quest'])) { $_GET['quest'] = ""; }
?>
	<div class="menu">TransAtlasDB Summary</div>
	<table width=80% ><tr><td valign="top" width=280pt>
<?php
	//create query for DB display
	if ($_GET['quest'] == 'samples') { //if samples
?>
	<div class="metamenu"><a href="about.php">Organisms</a></div>
	<div class="metamenu"><a href="about.php?quest=animal">Animals</a></div>
	<div class="metactive"><a href="about.php?quest=samples">Samples</a></div>
	<div class="metamenu"><a href="about.php?quest=samplesprocessed">Samples Processed</a></div>
	<div class="metamenu"><a href="about.php?quest=database">Database content</a></div>
	</td><td valign="top">
	<?php
		$result = $db_conn->query("select Organism, Tissue, count(*) Count from Animal a join Sample b on a.animalid = b.derivedfrom group by organism, tissue");
		$result2 = "null";
		echo '<div class="dift"><p>Summary of Samples.</p>';
		about_display($result, $result2);
	} elseif ($_GET['quest'] == 'samplesprocessed') { // if samplesprocessed
?>
	<div class="metamenu"><a href="about.php">Organisms</a></div>
	<div class="metamenu"><a href="about.php?quest=animal">Animals</a></div>
	<div class="metamenu"><a href="about.php?quest=samples">Samples</a></div>
	<div class="metactive"><a href="about.php?quest=samplesprocessed">Samples Processed</a></div>
	<div class="metamenu"><a href="about.php?quest=database">Database content</a></div>
	</td><td valign="top">
	<?php
		$result = $db_conn->query("select a.organism Organism, format(count(b.sampleid),0) Recorded, format(count(c.sampleid),0) Processed , format(count(d.sampleid),0) Genes, format(count(e.sampleid),0) Variants from Animal a join Sample b on a.animalid = b.derivedfrom left outer join vw_sampleinfo c on b.sampleid = c.sampleid left outer join GeneStats d on c.sampleid = d.sampleid left outer join VarSummary e on c.sampleid = e.sampleid group by a.organism");
		$result2 = $db_conn->query("select format(count(b.sampleid),0), format(count(c.sampleid),0), format(count(d.sampleid),0), format(count(e.sampleid),0) from Animal a join Sample b on a.animalid = b.derivedfrom left outer join vw_sampleinfo c on b.sampleid = c.sampleid left outer join GeneStats d on c.sampleid = d.sampleid left outer join VarSummary e on c.sampleid = e.sampleid"); #FINAL ROW
		echo '<div class="dift"><p>Summary of Samples processed.</p>';
		about_display($result, $result2);
	} elseif ($_GET['quest'] == 'database') { //if database
?>
	<div class="metamenu"><a href="about.php">Organisms</a></div>
	<div class="metamenu"><a href="about.php?quest=animal">Animals</a></div>
	<div class="metamenu"><a href="about.php?quest=samples">Samples</a></div>
	<div class="metamenu"><a href="about.php?quest=samplesprocessed">Samples Processed</a></div>
	<div class="metactive"><a href="about.php?quest=database">Database content</a></div>
	</td><td valign="top">
	<?php
		$result = $db_conn->query("select organism Species, format(sum(genes),0) Genes, format(sum(totalvariants),0) Variants from vw_sampleinfo group by species");
		$result2 = $db_conn->query("select format(sum(genes),0) Genes, format(sum(totalvariants ),0) Variants from vw_sampleinfo"); #FINAL ROW
		echo '<div class="dift"><p>Summary of Database Content.</p>';
		about_display($result, $result2);
	} elseif ($_GET['quest'] == 'animal') { //if animal
?>
	<div class="metamenu"><a href="about.php">Organisms</a></div>
	<div class="metactive"><a href="about.php?quest=animal">Animals</a></div>
	<div class="metamenu"><a href="about.php?quest=samples">Samples</a></div>
	<div class="metamenu"><a href="about.php?quest=samplesprocessed">Samples Processed</a></div>
	<div class="metamenu"><a href="about.php?quest=database">Database content</a></div>
	</td><td valign="top">
	<?php
		$result = $db_conn->query("select a.organism Organism, a.animalid Animals, format(count(b.sampleid),0) Samples from Animal a join Sample b where a.animalid = b.derivedfrom group by a.organism, a.animalid");
		$result2 = $db_conn->query("select format(count(distinct a.animalid),0) Animals, format(count(distinct b.sampleid),0) Samples from Animal a join Sample b where a.animalid = b.derivedfrom group by a.organism"); #FINAL ROW
		echo '<div class="dift"><p>Summary of Animals .</p>';
		about_display($result, $result2);
	} else { //if organisms
?>
	<div class="metactive"><a href="about.php">Organisms</a></div>
	<div class="metamenu"><a href="about.php?quest=animal">Animals</a></div>
	<div class="metamenu"><a href="about.php?quest=samples">Samples</a></div>
	<div class="metamenu"><a href="about.php?quest=samplesprocessed">Samples Processed</a></div>
	<div class="metamenu"><a href="about.php?quest=database">Database content</a></div>
	</td><td valign="top">
	<?php
		$result = $db_conn->query("select Organism, count(*) as Count from Animal group by organism");
		$result2 = $db_conn->query("select count(*) from Animal"); #FINAL ROW
		echo '<div class="dift"><p>Summary of Organisms.</p>';
		about_display($result, $result2);
	}

	if ($db_conn->errno) {
		echo "<div>";
		echo "<span><strong>Error with query.</strong></span>";
		echo "<span><strong>Error number: </strong>$db_conn->errno</span>";
		echo "<span><strong>Error string: </strong>$db_conn->error</span>";
		echo "</div>";
	}
?>
<!-- QUERY -->

</div>
</td></tr>
</table>
  </div>
<?php
  $db_conn->close();
?>

</body>
</html>
