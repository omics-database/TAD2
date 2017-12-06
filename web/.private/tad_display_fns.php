<?php //About page display
function about_display($result, $result2){
    $num_rows = $result->num_rows;
    echo '<form action="" method="post">';
    echo '<table class="metadata"><tr>';    
    $j = 0;
    while ($j < $result->field_count) { 
        $meta = $result->fetch_field_direct($j);
        echo '<th class="metadata" id="' . $meta->name . '">'.$meta->name.'</th>';
        $j++;
    }
    echo '</tr>';
    for ($i = 0; $i < $num_rows; $i++) {
      if ($i % 2 == 0) {
          echo "<tr class=\"odd\">";
      } else {
          echo "<tr class=\"even\">";
      }
      $row = $result->fetch_assoc();
      $j = 0;
      while ($j < $result->field_count) {
        $meta = $result->fetch_field_direct($j);
        echo '<td headers="' . $meta->name . '" class="metadata"><center>' . $row[$meta->name] . '</center></td>';
        $j++;
      }
      echo "</tr>";
    }
    if ($result2 != "null") {
        $j = 0;
        echo '<tr style="background-color:#f6fbf1;"><td class="metadata" align="right"><font style="font-size:100%;font-weight:bolder;letter-spacing:1px;">Total</font></td>';
        $row = $result2->fetch_assoc();
        while ($j < $result2->field_count) { 
            $meta = $result2->fetch_field_direct($j);
            echo '<td align="right" class="metadata" id="' . $meta->name . '"><font style="font-size:100%;font-weight:bolder;letter-spacing:1px;">'.$row[$meta->name].'</font></td>';
            $j++;
        }
        echo '</tr>';
    }
    echo '</table></form>';
}
?>

<?php
function db_display($result){
    $num_rows = $result->num_rows;
    echo '<form action="" method="post">';
    echo '<table class="metadata"><tr>';    
    $meta = $result->fetch_field_direct(0); echo '<th class="metadata" id="' . $meta->name . '">Sample Id</th>';
    $meta = $result->fetch_field_direct(1); echo '<th class="metadata" id="' . $meta->name . '">Animal Id</th>';
    $meta = $result->fetch_field_direct(2); echo '<th class="metadata" id="' . $meta->name . '">Organism</th>';
    $meta = $result->fetch_field_direct(3); echo '<th class="metadata" id="' . $meta->name . '">Tissue</th>';
    $meta = $result->fetch_field_direct(4); echo '<th class="metadata" id="' . $meta->name . '">Person</th>';
    $meta = $result->fetch_field_direct(5); echo '<th class="metadata" id="' . $meta->name . '">Organization</th>';
    $meta = $result->fetch_field_direct(6); echo '<th class="metadata" id="' . $meta->name . '">Animal Description</th>';
    $meta = $result->fetch_field_direct(7); echo '<th class="metadata" id="' . $meta->name . '">Sample Description</th>';
    $meta = $result->fetch_field_direct(8); echo '<th class="metadata" id="' . $meta->name . '">Date</th>';
    
    echo '</tr>';
    for ($i = 0; $i < $num_rows; $i++) {
      if ($i % 2 == 0) {
          echo "<tr class=\"odd\">";
      } else {
          echo "<tr class=\"even\">";
      }
      $row = $result->fetch_assoc();
      $j = 0;
      while ($j < $result->field_count) {
        $meta = $result->fetch_field_direct($j);
        echo '<td headers="' . $meta->name . '" class="metadata"><center>' . $row[$meta->name] . '</center></td>';
        $j++;
      }
      echo "</tr>";
    }
    echo '</table></form>';
}
?>

<?php //Delete data
function db_delete($table, $db_conn) {
    if (!empty($_REQUEST['accept'])) {
        echo '';
		$all_stat = $db_conn->query("select sampleid from Sample where sampleid = '".$_POST['samplename']."'");
        $total_rows = $all_stat->num_rows;
		if ($total_rows >= 1) {
			$darray = array('Sample Information');
		
			$all_stat = $db_conn->query("select sampleid from MapStats where sampleid = '".$_POST['samplename']."'");
			$total_rows = $all_stat->num_rows; if ($total_rows >=1) { array_push($darray,'Alignment Information'); }
		
			$all_stat = $db_conn->query("select sampleid from GeneStats where sampleid = '".$_POST['samplename']."'");
			$total_rows = $all_stat->num_rows; if ($total_rows >= 1) { array_push($darray,'Expression Information'); }
		
			$all_stat = $db_conn->query("select sampleid from VarSummary where sampleid = '".$_POST['samplename']."'");
			$total_rows = $all_stat->num_rows; if ($total_rows >= 1) { array_push($darray,'Variant Information'); }
		
			echo '<form action="" method="post"><table class="lines">';
			echo '<tr><td colspan="2"><center>Select the details to remove for sampleid "'.$_POST['samplename'].'"</center></td></tr>';
			foreach ($darray as $index => $ddd) {
				echo '<tr><th class="lines"><strong>'.$ddd.'</strong><th><td><input type="checkbox" name="data_delete[]" value="'.$index.'"></td></tr>';
			}
			echo '<tr><td colspan="2"><center><input type="submit" name="removed" class="import" value="are you sure?"/></center></td></tr>';
			echo '</table></form>';
		} else {print 'SampleID "'.$_POST['samplename'].'" does not exist in the database'; }
	$count = count($darray);
	return $darray;
	}
}
?>


<?php //Accept input
function db_accept($table, $db_conn) {
    if (!empty($_REQUEST['accept'])) {
        echo '';
  ?>
        <form action="" method="post">
            <table class="lines">
					<tr>
						<th class="lines"><strong>Sample Name</strong></th>
                        <td class="lines"><input type="hidden" class="port" name="samplename"<?php if(!empty($db_conn)){echo 'value="'.$_POST['samplename'].'"/>'.$_POST['samplename'];}?></td>	<!--sample name-->
					</tr><tr>
						<th class="lines"><strong>Sample description</strong></th>
						<td class="lines"><input type="hidden" class="port" name="sampledesc"<?php if(!empty($db_conn)){echo 'value="'.$_POST['sampledesc'].'"/>'.$_POST['sampledesc'];}?></td>	<!--sample desc -->
					</tr><tr>
						<th class="lines"><strong>Animal ID</strong></th>
						<td class="lines"><input type="hidden" class="port" name="animalid"<?php if(!empty($db_conn)){echo 'value="'.$_POST['animalid'].'"/>'.$_POST['animalid'];}?></td>	<!--animalid-->
					</tr><tr>
						<th class="lines"><strong>Animal Description</strong></th>
						<td class="lines"><input type="hidden" class="port" name="animaldesc"<?php if(!empty($db_conn)){echo 'value="'.$_POST['animaldesc'].'"/>'.$_POST['animaldesc'];}?></td>	<!--animalid-->
					</tr><tr>
						<th class="lines"><strong>Organism</strong></th>
						<td class="lines"><input type="hidden" class="port" name="organism"<?php if(!empty($db_conn)){echo 'value="'.$_POST['organism'].'"/>'.$_POST['organism'];}?></td>	<!--organism-->
					</tr><tr>
						<th class="lines"><strong>Organism Part</strong></th>
						<td class="lines"><input type="hidden" class="port" name="part"<?php if(!empty($db_conn)){echo 'value="'.$_POST['part'].'"/>'.$_POST['part'];}?></td>	<!--part-->
					</tr><tr>
						<th class="lines"><strong>First Name</strong></th>
						<td class="lines"><input type="hidden" class="port" name="firstname"<?php if(!empty($db_conn)){echo 'value="'.$_POST['firstname'].'"/>'.$_POST['firstname'];}?></td>	<!--first name-->
					</tr><tr>
						<th class="lines"><strong>Middle Initial</strong></th>
						<td class="lines"><input type="hidden" class="port" name="middle"<?php if(!empty($db_conn)){echo 'value="'.$_POST['middle'].'"/>'.$_POST['middle'];}?></td>	<!--middle-->
					</tr><tr>
						<th class="lines"><strong>Last Name</strong></th>
						<td class="lines"><input type="hidden" class="port" name="lastname"<?php if(!empty($db_conn)){echo 'value="'.$_POST['lastname'].'"/>'.$_POST['lastname'];}?></td>	<!--last-->
					</tr><tr>
						<th class="lines"><strong>Organization</strong></th>
						<td class="lines"><input type="hidden" class="port" name="organization"<?php if(!empty($db_conn)){echo 'value="'.$_POST['organization'].'"/>'.$_POST['organization'];}?></td>	<!--org-->
					</tr>
					<tr><td colspan="2"><center><input type="submit" name="reset" class="import" value="reject"/><input type="submit" name="verified" class="import" value="accept"/></center></td></tr>
				</table></form>
    <?php
    }
}
?>

<?php //Insert input
function db_insert($table, $db_conn) {
    if (!empty($_REQUEST['verified'])) {
        $sheetid = $_POST['firstname']." ".$_POST['middle']." ".$_POST['lastname'];
        if (strlen($sheetid) > 3 ) { //Person name        
            $all_stat = $db_conn->query("select personid from Person where personid = '$sheetid'");
            $total_rows = $all_stat->num_rows;
            if ($total_rows < 1) { // if person is not in the database
                $query = "INSERT INTO Person (personid, firstname, lastname, middleinitial) VALUES ('$sheetid', '".$_POST['firstname']."', '".$_POST['middle']."', '".$_POST['lastname']."')";
                $result = $db_conn->query($query);
                
                if (!$result) {
                    echo "<span><strong>Insert unsuccessful.</strong></span><br>";
                    echo "<span><strong>Query: </strong>$query</span><br>";
                    echo "<span><strong>Errormessage: </strong>" . $db_conn->error . "</span>";
                }
            }
        }
        if (strlen($_POST['organization']) > 0){ //Organization
            $query = "select organizationname from Organization where organizationname = '".$_POST['organization']."'";
            $all_stat = $db_conn->query($query);
            $total_rows = $all_stat->num_rows;
            if ($total_rows < 1) { // if organization is not in the database
                $query = "INSERT INTO Organization (organizationname) values ('".$_POST['organization']."')";
                $result = $db_conn->query($query);
                
                if (!$result) {
                    echo "<span><strong>Insert unsuccessful.</strong></span><br>";
                    echo "<span><strong>Query: </strong>$query</span><br>";
                    echo "<span><strong>Errormessage: </strong>" . $db_conn->error . "</span>";
                }
            }
        }
        $query = "select organism from Organism where organism = '".$_POST['organism']."'";
        $all_stat = $db_conn->query($query); //organism
        $total_rows = $all_stat->num_rows;
        if ($total_rows < 1) { // if organism is not in the database
            $query = "INSERT INTO Organism (organism) values ('".$_POST['organism']."')";
            $result = $db_conn->query($query);

            if (!$result) {
                echo "<span><strong>Insert unsuccessful.</strong></span><br>";
                echo "<span><strong>Query: </strong>$query</span><br>";
                echo "<span><strong>Errormessage: </strong>" . $db_conn->error . "</span>";
            }
        }
        $query = "select animalid from Animal where animalid = '".$_POST['animalid']."'";
        $all_stat = $db_conn->query($query); //animalid
        $total_rows = $all_stat->num_rows;
        if ($total_rows < 1) { // if animalid is not in the database
            $query = "INSERT INTO Animal (animalid, organism,description) values ('".$_POST['animalid']."', '".$_POST['organism']."', '".$_POST['animaldesc']."')";
            $result = $db_conn->query($query);
            
            if (!$result) {
                echo "<span><strong>Insert unsuccessful.</strong></span><br>";
                echo "<span><strong>Query: </strong>$query</span><br>";
                echo "<span><strong>Errormessage: </strong>" . $db_conn->error . "</span>";
            }
        }
        $query = "select tissue from Tissue where tissue = '".$_POST['part']."'";
        $all_stat = $db_conn->query($query); //tissue
        $total_rows = $all_stat->num_rows;
        if ($total_rows < 1) { // if tissue is not in the database
            $query = "INSERT INTO Tissue (tissue) values ('".$_POST['part']."')";
            $result = $db_conn->query($query);
            
            if (!$result) {
                echo "<span><strong>Insert unsuccessful.</strong></span><br>";
                echo "<span><strong>Query: </strong>$query</span><br>";
                echo "<span><strong>Errormessage: </strong>" . $db_conn->error . "</span>";
            }
        }
        $all_stat = $db_conn->query("select sampleid from Sample where sampleid = '".$_POST['samplename']."'"); //sample
        $total_rows = $all_stat->num_rows;
        if ($total_rows < 1) { // if sample is not in the database
            
            $otherdate = shell_exec("date +'%Y-%m-%d %T'");  $importdate = substr($otherdate, 0, -1);
            $query = "INSERT INTO Sample (sampleid, tissue, derivedfrom, description,date) values ('".$_POST['samplename']."', '".$_POST['part']."', '".$_POST['animalid']."', '".$_POST['sampledesc']."', '".$importdate."')";
            $result = $db_conn->query($query);
            $personresult = $db_conn->query("insert into SamplePerson (sampleid,personid) values ('".$_POST['samplename']."', '$sheetid')");
            $orgresult = $db_conn->query("insert into SampleOrganization (sampleid,organizationname) values ('".$_POST['samplename']."', '".$_POST['organization']."')");
            if (!$result) {
                echo "<span><strong>Insert unsuccessful.</strong></span><br>";
                echo "<span><strong>Query:</strong>$query</span><br>";
                echo "<span><strong>Errormessage: </strong>" . $db_conn->error . "</span>";
            } else {
                echo "<span><strong>Insert successful.</strong></span><br>";
            }
        } else {
            echo "<span><strong>Insert unsuccessful.</strong></span><br>";
            echo "<span><strong>Error: </strong> Sample ID '".$_POST['samplename']."' already in the database</span><br>";
        }
        echo '<div>';
        echo '</div>';
    }
}
?>

<?php 
function meta_display($result) {
    $num_rows = $result->num_rows;
    echo '<br><table class="metadata"><tr>';
    echo '<th align="left" width=40pt bgcolor="white"><font size="2" color="red">Select All</font><input type="checkbox" id="selectall" onClick="selectAll(this)" /></th>';
    $meta = $result->fetch_field_direct(0); echo '<th class="metadata" id="' . $meta->name . '">Sample Id</th>';
    $meta = $result->fetch_field_direct(1); echo '<th class="metadata" id="' . $meta->name . '">Animal Id</th>';
    $meta = $result->fetch_field_direct(2); echo '<th class="metadata" id="' . $meta->name . '">Organism</th>';
    $meta = $result->fetch_field_direct(3); echo '<th class="metadata" id="' . $meta->name . '">Tissue</th>';
    $meta = $result->fetch_field_direct(4); echo '<th class="metadata" id="' . $meta->name . '">Sample Description</th>';
    $meta = $result->fetch_field_direct(5); echo '<th class="metadata" id="' . $meta->name . '">Date</th>';
    $meta = $result->fetch_field_direct(6); echo '<th class="metadata" id="' . $meta->name . '">Gene Status</th>';
    $meta = $result->fetch_field_direct(7); echo '<th class="metadata" id="' . $meta->name . '">Variant Status</th></tr>';

    for ($i = 0; $i < $num_rows; $i++) {
        if ($i % 2 == 0) {
            echo "<tr class=\"odd\">";
        } else {
            echo "<tr class=\"even\">";
        }
        $row = $result->fetch_assoc();
        echo '<td><input type="checkbox" name="meta_data[]" value="'.$row['sampleid'].'"></td>';
        $j = 0;
        while ($j < $result->field_count) {
            $meta = $result->fetch_field_direct($j);
            if ($row[$meta->name] == "done"){
                echo '<td headers="' . $meta->name . '" class="metadata"><center><img src=".images/done.png" style="display:block;" width="20pt" height="20pt" ></center></td>';
            } else {
                echo '<td headers="' . $meta->name . '" class="metadata"><center>' . $row[$meta->name] . '</center></td>';
            }
            $j++;
        }
        echo "</tr>";
    }
    echo "</table></form>";
}
?>


<?php 
function metavw_display($result) {
    $num_rows = $result->num_rows;
    echo '<br><table class="metadata"><tr style="font-size:1.8vh;">';
    echo '<th align="left" width=40pt bgcolor="white"></th><th class="metadata" colspan=5>Analysis Summary</th><th class="metadata" colspan=3 style="color:#306269;">Mapping Metadata</th><th class="metadata" colspan=2 style="color:#306937;">Expression Metadata</th><th class="metadata" colspan=3 style="color:#693062;">Variant Metadata</th></tr><tr>';
    echo '<th align="left" width=40pt bgcolor="white"><font size="2" color="red">Select All</font><input type="checkbox" id="selectall" onClick="selectAll(this)" /></th>';
    $meta = $result->fetch_field_direct(0); echo '<th class="metadata" id="' . $meta->name . '">Sample Id</th>';
    $meta = $result->fetch_field_direct(1); echo '<th class="metadata" id="' . $meta->name . '">Total Fastq reads</th>';
    $meta = $result->fetch_field_direct(2); echo '<th class="metadata" id="' . $meta->name . '">Alignment Rate</th>';
    $meta = $result->fetch_field_direct(3); echo '<th class="metadata" id="' . $meta->name . '">Genes</th>';
    $meta = $result->fetch_field_direct(4); echo '<th class="metadata" id="' . $meta->name . '">Variants</th>';
    $meta = $result->fetch_field_direct(5); echo '<th class="metadata" style="color:#306269;" id="' . $meta->name . '">Mapping Tool</th>';
    $meta = $result->fetch_field_direct(6); echo '<th class="metadata" style="color:#306269;" id="' . $meta->name . '">Annotation file format</th>';
    $meta = $result->fetch_field_direct(7); echo '<th class="metadata" style="color:#306269;" id="' . $meta->name . '">Date</th>';
    $meta = $result->fetch_field_direct(8); echo '<th class="metadata" style="color:#306937;" id="' . $meta->name . '">Differential Expression Tool</th>';
    $meta = $result->fetch_field_direct(9); echo '<th class="metadata" style="color:#306937;" id="' . $meta->name . '">Date</th>';
    $meta = $result->fetch_field_direct(10); echo '<th class="metadata" style="color:#693062;" id="' . $meta->name . '">Variant Tool</th>';
    $meta = $result->fetch_field_direct(11); echo '<th class="metadata" style="color:#693062;" id="' . $meta->name . '">Variant Annotation Tool</th>';
    $meta = $result->fetch_field_direct(12); echo '<th class="metadata" style="color:#693062;" id="' . $meta->name . '">Date</th>';
    

    for ($i = 0; $i < $num_rows; $i++) {
        if ($i % 2 == 0) {
            echo "<tr class=\"odd\">";
        } else {
            echo "<tr class=\"even\">";
        }
        $row = $result->fetch_assoc();
        echo '<td><input type="checkbox" name="meta_data[]" value="'.$row['sampleid'].'"></td>';
        $j = 0;
        while ($j < $result->field_count) {
            $meta = $result->fetch_field_direct($j);
            if ($row[$meta->name] == "done"){
                echo '<td headers="' . $meta->name . '" class="metadata"><center><img src=".images/done.png" style="display:block;" width="10%" height="10%" ></center></td>';
            } else {
                echo '<td headers="' . $meta->name . '" class="metadata"><center>' . $row[$meta->name] . '</center></td>';
            }
            $j++;
        }
        echo "</tr>";
    }
    echo "</table></form>";
}
?>
<?php
function tabs_to_table($input) {
    //define replacement constants
    define('TAB_REPLACEMENT', "</center></td><td class='metadata'><center>");
    define('NEWLINE_BEGIN', "<tr%s><td class='metadata'><center>");
    define('NEWLINE_END', "</center></td></tr>");
    define('TABLE_BEGIN', "<table class='metadata'><tr><th class='metadata'>");
    define('TABLE_END', "</center></td></tr></table>");
    define('TAB_HEADER', "</th><th class='metadata'>");
    define('HEADER_END', "</th></tr>");

    //split the rows
    $rows = preg_split  ('/\n/'  , $input); $header = array_slice($rows,0,1); $rest = array_splice($rows,1);
    foreach ($header as $index => $row) {
        $row = preg_replace ('/\t/', TAB_HEADER , $row);
        $output = $row . HEADER_END;
    }      
    foreach ($rest as $index => $row) {
        $row = preg_replace  ('/\t/'  , TAB_REPLACEMENT  , $row);
        $output .= sprintf(NEWLINE_BEGIN, ($index%2?"":' class="odd"')) . $row . NEWLINE_END;
    }
    $input = TABLE_BEGIN. $output . "</table>";
    return ($input);
}
?>
