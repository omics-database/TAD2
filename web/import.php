<?php				
	session_start();
	require_once('all_fns.php');
	theader();
	$newdate = shell_exec("date +%Y-%m-%d");
	$table = "vw_metadata";
	$stat = "import";

?>
<?php
	if ($_GET['quest'] == 'manual') {
		$stat = "manual";
		if (isset($_POST['accept'])) {
			$_POST['samplename'] = strtoupper($_POST['samplename']);
			$samplename = strtoupper($_POST['samplename']);
			$sampledesc = $_POST['sampledesc'];
			$animalid = $_POST['animalid'];
			$animaldesc = $_POST['animaldesc'];
			$species= $_POST['organism'];
			$_POST['part'] = strtolower($_POST['part']);
			$part = strtolower($_POST['part']);
			$firstname= $_POST['firstname'];
			$middle = $_POST['middle'];
			$lastname = $_POST['lastname'];
			$organization = $_POST['organization'];
		}
?>
	<div class="menu">TransAtlasDB Data Import</div>
	<table width=100%><tr><td valign="top" width=280pt>
	<br><br>
	<div class="metamenu"><a href="import.php">Upload Files</a></div>
	<div class="metactive"><a href="import.php?quest=manual">Manual Entry</a></div>
	<!--<div class="metamenu"><a href="import.php?quest=delete">Remove Data</a></div>-->
	</td><td>
	<div class="dift"><p>Samples Metadata Manual entry into the database.</p>
		<table><tr><td>
			<form action="" method="post">	
				<table class="border" border="0">
					<tr>
						<th class="border"><strong>Sample Name</strong> <font color=red>*</font></th>
						<td class="borders"><input type="text" class="forms" name="samplename"<?php if(!empty($db_conn)){echo 'value="'.$samplename.'"';}?></td>	<!--sample name-->
					</tr><tr>
						<th class="border"><strong>Sample description</strong></th>
						<td class="borders"><input type="text" class="forms" name="sampledesc"<?php if(!empty($db_conn)){echo 'value="'.$sampledesc.'"';}?></td>	<!--sample desc -->
					</tr><tr>
						<th class="border"><strong>Animal ID</strong> <font color=red>*</font></th>
						<td class="borders"><input type="text" class="forms" name="animalid"<?php if(!empty($db_conn)){echo 'value="'.$animalid.'"';}?>/></td>	<!--animalid-->
					</tr><tr>
						<th class="border"><strong>Animal Description</strong></th>
						<td class="borders"><input type="text" class="forms" name="animaldesc"<?php if(!empty($db_conn)){echo 'value="'.$animaldesc.'"';}?>/></td>	<!--animalid-->
					</tr><tr>
						<th class="border"><strong>Organism</strong> <font color=red>*</font></th>
						<td class="borders"><input type="text" class="forms" name="organism"<?php if(!empty($db_conn)){echo 'value="'.$species.'"';}?>/></td>	<!--organism-->
					</tr><tr>
						<th class="border"><strong>Organism Part</strong> <font color=red>*</font></th>
						<td class="borders"><input type="text" class="forms" name="part"<?php if(!empty($db_conn)){echo 'value="'.$part.'"';}?>/></td>	<!--part-->
					</tr><tr>
						<th class="border"><strong>First Name</strong></th>
						<td class="borders"><input type="text" class="forms" name="firstname"<?php if(!empty($db_conn)){echo 'value="'.$firstname.'"';}?>/></td>	<!--first name-->
					</tr><tr>
						<th class="border"><strong>Middle Initial</strong></th>
						<td class="borders"><input type="text" class="forms" name="middle"<?php if(!empty($db_conn)){echo 'value="'.$middle.'"';}?>/></td>	<!--middle-->
					</tr><tr>
						<th class="border"><strong>Last Name</strong></th>
						<td class="borders"><input type="text" class="forms" name="lastname"<?php if(!empty($db_conn)){echo 'value="'.$lastname.'"';}?>/></td>	<!--last-->
					</tr><tr>
						<th class="border"><strong>Organization</strong></th>
						<td class="borders"><input type="text" class="forms" name="organization"<?php if(!empty($db_conn)){echo 'value="'.$organization.'"';}?>/></td>	<!--org-->
					</tr>
					<tr><td class="border" colspan="7"><center><input type="submit" name="accept" value="insert"/></center></td></tr>
				</table>
			</form>
		</td><td><div style="padding: 0 10pt; margin: 0 50pt;background-color: #f1f0f1;">
<?php
		if ((!empty($_POST['samplename'])) && (!empty($_POST['organism'])) && (!empty($_POST['animalid'])) && (!empty($_POST['part']))) {
			db_accept("Sample", $db_conn);
			db_insert("Sample", $db_conn);
		}
?>
		</div></td></tr></table>
	</div></td></tr></table>
<?php
	} else { //import upload
?>
	<div class="menu">TransAtlasDB Data Upload</div>
	<table width=100%><tr><td valign="top" width=280pt>
	<br><br>
	<div class="metactive"><a href="import.php">Upload Files</a></div>
	<div class="metamenu"><a href="import.php?quest=manual">Manual Entry</a></div>
	<!--<div class="metamenu"><a href="import.php?quest=delete">Remove Data</a></div>-->
	</td><td>
	<div class="dift"><p>Samples Metadata or RNASeq Data Analysis results upload and import to the database.</p>
		<table><tr><td>
		<ul>
            <li><p>Samples Metadata<br>
                N.B. Samples metadata file can either be the FAANG samples form or the tab-delimited file <a href="https://modupeore.github.io/TransAtlasDB/sample.html" target="_blank">provided</a>.
                <form action="" method="post" enctype="multipart/form-data">
                    Select metadata file:
                    <input type="file" name="fileToUpload" id="fileToUpload">
                    <input type="submit" value="Import to database" name="metasubmit">
                </form>
            </p></li>
            <li><p>Sample Analysis Results<br>
				N.B. Samples analysis results can only be imported using the perl toolkit.<br>
				<code>perl tad-import -data2db</code>
            </p></li>
        </ul>
		</td><td><div style="padding: 0 10pt; margin: 0 50pt;background-color: #f1f0f1;">
<?php
	if ((!empty($_FILES['fileToUpload']['name']))) {
		$target_file = "uploads/" . basename($_FILES["fileToUpload"]["name"]);
		$uploadOk = 1;
		$FileType = pathinfo($target_file,PATHINFO_EXTENSION);
		if(isset($_POST["metasubmit"])) {
			$check = filesize($_FILES["fileToUpload"]["tmp_name"]);
			if($check !== false) {
			    $uploadOk = 1;
			} else {
			    echo "File is not valid.";
			    $uploadOk = 0;
			}
		}

		// Allow certain file formats
		if($FileType != "txt" && $FileType != "xls" && $FileType != "xlsx" ) {
		    $uploadOk = 0;
		} else {
		    if ($FileType == "txt") {
		        $query = "-w 1 -t";
		    } else {
		        $query = "-w 1 ";
		    }
		}
		// Check if $uploadOk is set to 0 by an error
		if ($uploadOk == 0) {
		    echo "Sorry, your file was not uploaded.";
		// if everything is ok, try to upload file
		} else {
		    if (move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file)) {
                echo "<span><strong>Upload successful.</strong></span><br>";
                echo "<span><strong>File: </strong>".basename($_FILES['fileToUpload']['name'])."</span><br>";
				$result = $db_conn->query("select sampleid from Sample where date = '$newdate'"); $number = $result->num_rows;
				$pquery = "perl $basepath/tad-import.pl -metadata $query uploads/".$_FILES['fileToUpload']['name'];
		//        print $pquery;
				shell_exec($pquery);
				$result = $db_conn->query("select sampleid from Sample where date = '$newdate'"); $newnumber = $result->num_rows;
				$oddnumber = $newnumber - $number;
				if ($oddnumber >= 1) {
					echo "<br><span><strong>Insert successful.</strong></span><br>";
					echo "<span><strong>$oddnumber </strong>row inserted.</span>";
				} else {
					echo "<br><span><strong>Insert status.</strong></span><br>";
					echo "<span><strong>No </strong>rows inserted.</span>";
				}
				$query = "rm -rf uploads/".$_FILES['fileToUpload']['name'];
				shell_exec($query);
		    } else {
		        echo "Sorry, there was an error uploading your file.";
		    }
		}
	}
?>
		</div></td></tr></table>
	</div></td></tr></table>
		
<?php			
	}
?>						

	</div></td></tr></table>
		<!-- Next Section -->
	<div class="menu">Summary of libraries currently in the database</div>
	<div class="xtra">
<?php	
	$query = "SELECT * FROM $table";
	$all_rows = $db_conn->query($query);
	$total_rows = $all_rows->num_rows;

	if (!empty($_REQUEST['order'])) {
    // if the sort option was used
		$_SESSION[$stat]['sort'] = $_POST['sort'];
		$_SESSION[$stat]['dir'] = $_POST['dir'];
		$_SESSION[$stat]['num_recs'] = $_POST['num_recs'];

		$terms = explode(",", $_POST['search']);
		$is_term = false;
		foreach ($terms as $term) {
		    if (trim($term) != "") {
		        $is_term = true;
		    }
		}
		$_SESSION[$stat]['select'] = $terms;
		$_SESSION[$stat]['column'] = $_POST['column'];

		$query = ("SELECT * FROM $table ");
		if ($is_term) {
		    $query .= "WHERE ";
		}
		foreach ($_SESSION[$stat]['select'] as $term) {
		    if (trim($term) == "") {
		        continue;
		    }
		    $query .= $_SESSION[$stat]['column'] . " LIKE '%" . trim($term) . "%' OR ";
		}
		$query = rtrim($query, " OR ");
		$query .= " ORDER BY " . $_SESSION[$stat]['sort'] . " " . $_SESSION[$stat]['dir'];

		$result = $db_conn->query($query);
		$num_total_result = $result->num_rows;
		if ($_SESSION[$stat]['num_recs'] != "all") {
		    $query .= " limit " . $_SESSION[$stat]['num_recs'];
		}
		unset($_SESSION[$stat]['txt_query']);
		} elseif (!empty($_SESSION[$stat]['sort'])) {
		$is_term = false;
		foreach ($_SESSION[$stat]['select'] as $term) {
		    if (trim($term) != "") {
		        $is_term = true;
		    }
		}
		$query = ("SELECT * FROM $table ");
		if ($is_term) {
		    $query .= "WHERE ";
		}
		foreach ($_SESSION[$stat]['select'] as $term) {
		    if (trim($term) == "") {
		        continue;
		    }
		    $query .= $_SESSION[$stat]['column'] . " LIKE '%" . trim($term) . "%' OR ";
		}
		$query = rtrim($query, " OR ");
		$query .= " ORDER BY " . $_SESSION[$stat]['sort'] . " " . $_SESSION[$stat]['dir'];
		$result = $db_conn->query($query);
		$num_total_result = $result->num_rows;

		if ($_SESSION[$stat]['num_recs'] != "all") {
		    $query .= " limit " . $_SESSION[$stat]['num_recs'];
		}
	} else {
    // if this is the first time, then just order by line and display all rows //default
		$query = "SELECT * FROM $table ORDER BY date desc limit 10";
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
	if (empty($_SESSION[$stat]['sort'])) {
	    $num_total_result = $num_results;
	}
?>
<!-- QUERY -->
<form action="" method="post">
    <p class="pages">
		<span>Search for: </span>
<?php
	if (!empty($_SESSION[$stat]['select'])) {
		echo '<input type="text" size="35" name="search" value="' . implode(",", $_SESSION[$stat]["select"]) . '"\"/>';
	} else {
		echo '<input type="text" size="35" name="search" placeholder="Enter variable(s) separated by commas (,)"/>';
	} 
?>
    <span> in </span>
    <select name="column">
        <?php
			$i = 0;
			$all_rows = $db_conn->query($query);
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
		</select> <!if ascending or descending...>
		<select name="dir">
			<option value="asc">ascending</option>
			<?php
				if (empty($_SESSION[$stat]['dir'])) {
					$_SESSION[$stat]['asc'] = "asc";
				}
				if ($_SESSION[$stat]['dir'] == "desc") {
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
				if (empty($_SESSION[$stat]['num_recs'])) {
					$_SESSION[$stat]['num_recs'] = "10";
				}
				if ($_SESSION[$stat]['num_recs'] == "20") {
					echo '<option selected value="20">20</option>';
				} else {
					echo '<option value="20">20</option>';
				}
				if ($_SESSION[$stat]['num_recs'] == "50") {
					echo '<option selected value="50">50</option>';
				} else {
					echo '<option value="50">50</option>';
				}
				if ($_SESSION[$stat]['num_recs'] == "all") {
					echo '<option selected value="all">all</option>';
				} else {
					echo '<option value="all">all</option>';
				}
			?> 
		</select>
		<span>records.</span>
		<input type="submit" name="order" value="Go"/></p>
</form>
<br>
<?php
echo '<form action="" method="post">';
echo "<span>" . $num_results . " out of " . $num_total_result . " search results displayed. (" . $total_rows . " total rows)</span>";
db_display($result);
?>
<?php
$result->free();
$db_conn->close();
?>
</div>
</body>
</html>
