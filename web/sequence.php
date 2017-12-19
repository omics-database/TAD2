<?php				
	session_start();
	require_once('all_fns.php');
	tmetadata(); 
?>
<?PHP
	//Database Attributes
	$table = "vw_seqstats";
	$query = "select * from $table ";
?>
	<div class="menu">TransAtlasDB Mapping Information</div>
	<table width=100%><tr><td width=280pt>
	<div class="metamenu"><a href="metadata.php">MetaData Information</a></div>
	<div class="metactive"><a href="sequence.php">Sequencing Information</a></div>
	</td><td>
	<div class="dift"><p>View bio-data of the RNA-Seq libraries processed.</p>

<?php
	//create query for DB display
	if (!empty($_REQUEST['order'])) {
		// if the sort option was used
		$_SESSION[$table]['sort'] = $_POST['sort'];
		$_SESSION[$table]['dir'] = $_POST['dir'];
		$_SESSION[$table]['num_recs'] = $_POST['num_recs'];

		$terms = explode(",", $_POST['select']);
		$is_term = false;
		foreach ($terms as $term) {
			if (trim($term) != "") {
				$is_term = true;
			}
		}
		$_SESSION[$table]['select'] = $terms;
		$_SESSION[$table]['column'] = $_POST['column'];
		
		if ($is_term) {
			$query .= "WHERE ";
		}
		foreach ($_SESSION[$table]['select'] as $term) {
			if (trim($term) == "") {
				continue;
			}
			$query .= $table.".".$_SESSION[$table]['column'] . " LIKE '%" . trim($term) . "%' OR ";
		}
		$query = rtrim($query, " OR ");
		$query .= " ORDER BY " . $table.".".$_SESSION[$table]['sort'] . " " . $_SESSION[$table]['dir'];

		$result = $db_conn->query($query);
		$num_total_result = $result->num_rows;
		if ($_SESSION[$table]['num_recs'] != "all") {
			$query .= " limit " . $_SESSION[$table]['num_recs'];
		}
	} elseif (!empty($_GET['libs'])) {
    //if the sort option was used
		$_SESSION[$table]['num_recs'] = "all";

		$terms = explode(",", $_GET['libs']);
		$is_term = false;
		foreach ($terms as $term) {
			if (trim($term) != "") {
				$is_term = true;
			}	
		}
		$_SESSION[$table]['select'] = $terms;
		$_SESSION[$table]['column'] = "sampleid";
		if ($is_term) {
		    $query .= "WHERE ";
		}
		foreach ($_SESSION[$table]['select'] as $term) {
			if (trim($term) == "") {
				continue;
			}
			$query .= $table.".".$_SESSION[$table]['column'] . " LIKE '%" . trim($term) . "%' OR ";
		}
		$query = rtrim($query, " OR ");
		$query .= " ORDER BY " . $table.".".$_SESSION[$table]['column'] . " " . $_SESSION[$table]['dir'];

		$result = $db_conn->query($query);
		$num_total_result = $result->num_rows;
		if ($_SESSION[$table]['num_recs'] != "all") {
			$query .= " limit " . $_SESSION[$table]['num_recs'];
		}
	} elseif (!empty($_SESSION[$table]['sort'])) {
		$is_term = false;
		foreach ($_SESSION[$table]['select'] as $term) {
			if (trim($term) != "") {
				$is_term = true;
			}
		}
		if ($is_term) {
			$query .= "WHERE ";
		}
		foreach ($_SESSION[$table]['select'] as $term) {
			if (trim($term) == "") {
				continue;
			}
			$query .= $table.".".$_SESSION[$table]['column'] . " LIKE '%" . trim($term) . "%' OR ";
		}
		$query = rtrim($query, " OR ");
		$query .= " ORDER BY " . $table.".".$_SESSION[$table]['sort'] . " " . $_SESSION[$table]['dir'];

		$result = $db_conn->query($query);
		$num_total_result = $result->num_rows;
	
		if ($_SESSION[$table]['num_recs'] != "all") {
			$query .= " limit " . $_SESSION[$table]['num_recs'];
		}
	} 
	$result = $db_conn->query($query);
	if ($db_conn->errno) {
		echo "<div>";
		echo "<span><strong>Error with query.</strong></span>";
		echo "<span><strong>Error number: </strong>$db_conn->errno</span>";
		echo "<span><strong>Error string: </strong>$db_conn->error</span>";
		echo "</div>";
	}

	$num_results = $result->num_rows;
	if (empty($_SESSION[$table]['sort'])) {
		$num_total_result = $num_results;
	}
?>
<!-- QUERY -->
<form action="" method="post">
    <p class="pages">
		<span>Search for: </span>
 <?php
	if (!empty($_SESSION[$table]['select'])) {
		echo '<input type="text" size="35" name="select" value="' . implode(",", $_SESSION[$table]["select"]) . '"\"/>';
	} else {
		echo '<input type="text" size="35" name="select" placeholder="Enter variable(s) separated by commas (,)"/>';
	} 
?>
    <span> in </span>
    <select name="column">
        <?php
			$i = 0;
			$all_rows = $db_conn->query("select sampleid, mappingtool, annotationfile, diffexpresstool, varianttool, variantannotationtool from $table");
			while ($i < $all_rows->field_count) {
			    $meta = $all_rows->fetch_field_direct($i);
			    echo '<option value="'.$meta->name.'">'. $meta->name.'</option>';
			    $i++;
			}
		?>
</select></p>
    <p class="pages" >
		<span>Sort by:</span>
		<select name="sort">
		    <?php
				$i = 0;
				while ($i < $all_rows->field_count) {
					$meta = $all_rows->fetch_field_direct($i);
					echo '<option value="' . $meta->name . '">' . $meta->name . '</option>';
					$i++;
				}
		    ?>
		</select> <!--if ascending or descending-->
		<select name="dir">
			<option value="asc">ascending</option>
			<?php
				if (empty($_SESSION[$table]['dir'])) {
					$_SESSION[$table]['dir'] = "asc";
				}
				if ($_SESSION[$table]['dir'] == "desc") {
					echo '<option selected value="desc">descending</option>';
				} else {
					echo '<option value="desc">descending</option>';
				}
			?>
		</select>
		<span>and show</span>
		<select name="num_recs">
			<option value="10">10</option>
			<?php
				if (empty($_SESSION[$table]['num_recs'])) {
					$_SESSION[$table]['num_recs'] = "10";
				}
				if ($_SESSION[$table]['num_recs'] == "20") {
					echo '<option selected value="20">20</option>';
				} else {
					echo '<option value="20">20</option>';
				}
				if ($_SESSION[$table]['num_recs'] == "50") {
					echo '<option selected value="50">50</option>';
				} else {
					echo '<option value="50">50</option>';
				}
				if ($_SESSION[$table]['num_recs'] == "all") {
					echo '<option selected value="all">all</option>';
				} else {
					echo '<option value="all">all</option>';
				}
			?> 
		</select>
		<span>records.</span><input type="submit" name="order" value="Go"/></p><br><br></div>
</form>
</div>
</td></tr></table>

<?php
  if(!empty($db_conn) && (!empty($_POST['order']) || !empty($_POST['meta_data']))) { //make sure an options is selected
	echo '<div class="menu">Results</div><div class="xtra">';
    if ($num_total_result == 0){ //Cross check if libraries selected are in the database
      echo '<center>No sequencing information were found with your search criteria.<br>
      There are no "'.implode(",", $_SESSION[$table]["select"]).'" in "'.$_SESSION[$table]['column'].'".<center>';
    }else { //Provide download options
      echo '<div class="xtra">';
      echo '<form action="" method="post">';
      echo "<span>" . $num_results . " out of " . $num_total_result . " search results displayed. ";
      echo '<input type="submit" name="downloadvalues" value="Download Selected Values"/></span>
	    <input type="submit" name="downloadfpkm" value="Download FPKM  Values"/></span>';
      metavw_display($result);
      if(!empty($_POST['meta_data']) && isset($_POST['downloadvalues'])) { //If download Metadata
        foreach($_POST['meta_data'] as $check) {
          $dataline .= '"'.$check.'",';
        }
        $dataline = rtrim($dataline, ",");
        $output = "OUTPUT/sequence_".$explodedate.".txt";
        $pquery = "perl $basepath/tad-export.pl -w -query 'select * from $table where $table.sampleid in ($dataline)' -o $output";
		shell_exec($pquery);
        print("<script>location.href='results.php?file=$output&name=sequenceinfo.txt'</script>");
      }
      elseif(!empty($_POST['meta_data']) && isset($_POST['downloadfpkm'])) { //If download fpkm
        foreach($_POST['meta_data'] as $check) {
          $dataline .= $check.",";
		  $newdataline .= '"'.$check.'",';
        }
        $dataline = rtrim($dataline, ",");$newdataline = rtrim($newdataline, ",");
		$output = "OUTPUT/fpkm_".$explodedate.".txt";
		$query = "select b.organism from Animal b join Sample a on a.derivedfrom = b.animalid where a.sampleid in ($newdataline) limit 1";
		$result = mysqli_query($db_conn,$query);
		$row = mysqli_fetch_array($result,MYSQLI_ASSOC);
		$organism = $row['organism'];
        
		$pquery = "perl $basepath/tad-export.pl -w -genexp --db2data --species '$organism' --samples '$dataline' --output $output";
		shell_exec($pquery);
        print("<script>location.href='results.php?file=$output&name=fpkm.txt'</script>");
      }
      elseif(!empty($_POST['meta_data']) && isset($_POST['transfervalues'])) { //If transfer to sequencing information page
        foreach($_POST['meta_data'] as $check) {
          $dataline .= $check.",";
        }
        $dataline = rtrim($dataline, ",");
        $_SESSION[$table]['store'] = "yes";
        print("<script>location.href='sequence.php?libs=$dataline'</script>");
      }
    }
  }

//Transfer from MetaData page
  elseif(!empty($db_conn) && (!empty($_GET['libs']))) { //make sure an options is selected
	echo '<div class="menu">Results</div><div class="xtra">';
    if ($num_total_result == 0){ //Cross check if libraries selected are in the database
      echo '<center>No results were found with your search criteria.<br>
      There are no "'.implode(",", $_SESSION[$table]["select"]).'" in "'.$_SESSION[$table]['column'].'".<center>';
    }else { //Provide download options
      echo '<div>';
      echo '<form action="" method="post">';
      echo "<span>" . $num_results . " out of " . $num_total_result . " search results displayed. ";
      echo '<input type="submit" name="downloadvalues" value="Download Selected Values"/></span>
	    <input type="submit" name="downloadfpkm" value="Download FPKM  Values"/></span><br>';
      metavw_display($result);
      if(!empty($_POST['meta_data']) && isset($_POST['downloadvalues'])) { //If download Metadata
        foreach($_POST['meta_data'] as $check) {
          $dataline .= '"'.$check.'",';
        }
        $dataline = rtrim($dataline, ",");
        $output = "OUTPUT/sequence_".$explodedate.".txt";
        $pquery = "perl $basepath/tad-export.pl -w -query 'select * from $table where $table.sampleid in ($dataline)' -o $output";
		shell_exec($pquery);
        print("<script>location.href='results.php?file=$output&name=sequenceinfo.txt'</script>");
      }
      elseif(!empty($_POST['meta_data']) && isset($_POST['downloadfpkm'])) { //If download fpkm
        foreach($_POST['meta_data'] as $check) {
          $dataline .= $check.",";
		  $newdataline .= '"'.$check.'",';
        }
        $dataline = rtrim($dataline, ",");$newdataline = rtrim($newdataline, ",");
		$output = "OUTPUT/fpkm_".$explodedate.".txt";
		$query = "select b.organism from Animal b join Sample a on a.derivedfrom = b.animalid where a.sampleid in ($newdataline) limit 1";
		$result = mysqli_query($db_conn,$query);
		$row = mysqli_fetch_array($result,MYSQLI_ASSOC);
		$organism = $row['organism'];
        
		$pquery = "perl $basepath/tad-export.pl -w -genexp --db2data --species '$organism' --samples '$dataline' --output $output";
		shell_exec($pquery);
        print("<script>location.href='results.php?file=$output&name=fpkm.txt'</script>");
      }
      elseif(!empty($_POST['meta_data']) && isset($_POST['transfervalues'])) { //If transfer to sequencing information page
        foreach($_POST['meta_data'] as $check) {
          $dataline .= $check.",";
        }
        $dataline = rtrim($dataline, ",");
        $_SESSION[$table]['store'] = "yes";
        print("<script>location.href='sequence.php?libs=$dataline'</script>");
      }
    }
  }
?>
  </div>
<?php
  $result ->free();
  $db_conn->close();
?>
</body>
</html>

