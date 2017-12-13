#!/usr/bin/env perl
use warnings;
use strict;
use Pod::Usage;
use Getopt::Long;
use File::Spec;
use File::Basename;
use threads;
use Thread::Queue;
use POSIX;
use Cwd qw(abs_path);
use lib dirname(abs_path $0) . '/lib';
use CC::Create;
use CC::Parse;

our $VERSION = '$ Version: 1 $';
our $DATE = '$ Date: 2017-05-05 05:14:00 (Fri, 05 May 2017) $';
our $AUTHOR= '$ Author:Modupe Adetunji <amodupe@udel.edu> $';

#--------------------------------------------------------------------------------

our ($verbose, $efile, $help, $man, $nosql, $vnosql, $gnosql, $cnosql, $log, $transaction);
our ($metadata, $tab, $excel, $datadb, $gene, $variant, $all, $vep, $annovar, $delete); #command options
our ($file2consider,$connect); #connection and file details
my ($sth,$dbh,$schema); #connect to database;

our ($sheetid, %NAME, %ORGANIZATION);

#data2db options
our ($found);
our (@allgeninfo);
my ($str, $ann, $ref, $seq,$allstart, $allend) = (0,0,0,0,0,0); #for log file
my ($refgenome, $refgenomename, $stranded, $sequences, $annotationfile, $mparameters, $gparameters, $cparameters, $vparameters); #for annotation file
my $additional;

#genes import
our ($bamfile, $alignfile, $version, $readcountfile, $genesfile, $deletionsfile, $insertionsfile, $transcriptsgtf, $junctionsfile, $variantfile, $vepfile, $annofile);
our ($kallistofile, $kallistologfile, $salmonfile, $salmonlogfile);
our ($total, $mapped, $alignrate, $deletions, $insertions, $junctions, $genes, $mappingtool, $annversion, $diffexpress, $counttool);
my (%ARFPKM,%CHFPKM, %BEFPKM, %CFPKM, %DFPKM, %TPM, %cfpkm, %dfpkm, %tpm, %DHFPKM, %DLFPKM, %dhfpkm, %dlfpkm, %ALL);
my (%HASHDBVARIANT, @VAR, @threads, $queue);
#variant import
our ( %VCFhash, %DBSNP, %extra, %VEPhash, %ANNOhash );
our ($varianttool, $verd, $variantclass, $vcount);
our ($itsnp,$itindel,$itvariants) = (0,0,0);

#nosql append
my (@nosqlrow, $showcase);
#date
my $date = `date +%Y-%m-%d`;

#--------------------------------------------------------------------------------

sub printerr; #declare error routine
our ($ibis, $ardea) = fastbit_name(); #ibis and ardea location
our $default = DEFAULTS(); #default error contact
processArguments(); #Process input

my %all_details = %{connection($connect, $default)}; #get connection details
if (length($ibis) < 1){ ($ibis, $ardea) = ($all_details{'FastBit-ibis'}, $all_details{'FastBit-ardea'}); } #alternative for ibis and ardea location 


#PROCESSING METADATA
if ($metadata){
	$dbh = mysql($all_details{'MySQL-databasename'}, $all_details{'MySQL-username'}, $all_details{'MySQL-password'}); #connect to mysql
  if ($tab) { #unix tab delimited file
		printerr "JOB:\t Importing Sample Information from tab-delimited file => $file2consider\n"; #status
		my %filecontent = %{ tabcontent($file2consider) }; #get content from tab-delimited file
		foreach my $row (sort keys %filecontent){
			undef %NAME; undef %ORGANIZATION;
			if (exists $filecontent{$row}{'sample name'}) { #sample name
				$filecontent{$row}{'organism part'} = lc($filecontent{$row}{'organism part'});
				my $sheetid = "$filecontent{$row}{'first name'} $filecontent{$row}{'middle initial'} $filecontent{$row}{'last name'}"; #scientist name
				if (length $sheetid > 3) { #Person Name 
					$sth = $dbh->prepare("select personid from Person where personid = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
					unless ($found) { # if person is not in the database
						$sth = $dbh->prepare("insert into Person (personid, firstname, lastname, middleinitial) values (?,?,?,?)");
						$sth->execute($sheetid, $filecontent{$row}{'first name'}, $filecontent{$row}{'last name'}, $filecontent{$row}{'middle initial'}) or die "\nERROR:\t Complication in Person table\n";
					}
					$NAME{$sheetid} = $sheetid;
				} else {
					undef $sheetid;
				}
				$sheetid = $filecontent{$row}{'organization'}; #organization name
				if ($sheetid) { #Organization Name
					$sth = $dbh->prepare("select organizationname from Organization where organizationname = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
					unless ($found) { # if person is not in the database
						$sth = $dbh->prepare("insert into Organization (organizationname) values ('$sheetid')");
						$sth->execute() or die "\nERROR:\t Complication in Organization table\n";
					}
					$ORGANIZATION{$sheetid} = $sheetid;
				} else {
					undef $sheetid;
				}
				if (exists $filecontent{$row}{'organism'}) { #organism name
					$sheetid = $filecontent{$row}{'organism'};
					$sth = $dbh->prepare("select organism from Organism where organism = '$sheetid'"); $sth->execute(); $found =$sth->fetch();
					unless ($found) { # if is not in the database
						$sth = $dbh->prepare("insert into Organism (organism) values ('$sheetid')");
						$sth->execute() or die "\nERROR:\t Complication in Organism table\n";
					}
					undef $sheetid;
				} else {
					die "\nFAILED:\t Error in tab-delimited file \"$file2consider\".\n\tCheck => ROW: $row, COLUMN: \"Organism\"\n";
				} #end if for animal info
				if (exists $filecontent{$row}{'derived from'}) { #animal id
					$sheetid = uc($filecontent{$row}{'derived from'});
					$sth = $dbh->prepare("select animalid from Animal where animalid = '$sheetid'"); $sth->execute(); $found =$sth->fetch();
					unless ($found) {
						printerr "NOTICE:\t Importing $sheetid to Animal table\n";
						$sth = $dbh->prepare("insert into Animal (animalid, organism) values (?,?)");
						$sth->execute($sheetid, $filecontent{$row}{'organism'} ) or die "\nERROR:\t Complication in Animal table\n";
					} else {
						$verbose and printerr "Duplicate: AnimalID '$sheetid' already exists in Animal table. Moving on\n";
					}
					undef $sheetid;
				} else {
					die "\nFAILED:\t Error in tab-delimited file \"$file2consider\".\n\tCheck => ROW: $row, COLUMN: \"Derived From\"\n";
				}
				if (exists $filecontent{$row}{'organism part'}) { #organism part / tissue
					$sheetid  = $filecontent{$row}{'organism part'}; 
					$sth = $dbh->prepare("select tissue from Tissue where tissue = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
					unless ($found) { # if is not in the database
						$sth = $dbh->prepare("insert into Tissue (tissue) values ('$sheetid')");
						$sth->execute() or die "\nERROR:\t Complication in Tissue table\n";
					}
					undef $sheetid;
				}
				$sheetid  = uc($filecontent{$row}{'sample name'}); #Sample Table
				$sth = $dbh->prepare("select sampleid from Sample where sampleid = '$sheetid'"); $sth->execute(); $found =$sth->fetch();
				unless ($found) { # if sample is not in the database
					printerr "NOTICE:\t Importing $sheetid to Sample table\n";
					$sth = $dbh->prepare("insert into Sample (sampleid, tissue, derivedfrom, description,date) values (?,?,?,?,?)");
					$sth->execute($sheetid, $filecontent{$row}{'organism part'}, $filecontent{$row}{'derived from'}, $filecontent{$row}{'sample description'},$date) or die "\nERROR:\t Complication in Sample table\n";
				} else {
					printerr "Duplicate: SampleID '$sheetid' already exists in Sample table. Moving on.\n";
					printerr "Optional: To delete $sheetid ; Execute: tad-import.pl -delete $sheetid\n";
				}
				foreach (keys %NAME) {
					$sth = $dbh->prepare("select sampleid, personid from SamplePerson where sampleid = '$sheetid' and personid = '$_'"); $sth->execute(); $found =$sth->fetch();
					unless ($found) { # if sample-person is not in the database
						$sth = $dbh->prepare("insert into SamplePerson (sampleid, personid) values (?,?)");
						$sth->execute($sheetid, $_) or die "\nERROR:\t Complication in SamplePerson table\n";
					}
				}
				foreach (keys %ORGANIZATION) {
					$sth = $dbh->prepare("select sampleid, organizationname from SampleOrganization where sampleid = '$sheetid' and organizationname = '$_'"); $sth->execute(); $found =$sth->fetch();
					unless ($found) { # if sample-organization is not in the database
						$sth = $dbh->prepare("insert into SampleOrganization (sampleid, organizationname) values (?,?)");
						$sth->execute($sheetid, $_) or die "\nERROR:\t Complication in SampleOrganization table\n";
					}
				}		
			} else {
				pod2usage("\nFAILED:\t Error in tab-delimited file \"$file2consider\".\n\tCheck => ROW: $row, COLUMN: \"Sample Name\"");
			} #end of if sample name is real
		} #end of foreach file content
	} #end of tab unix option
	else { #import faang excel sheet
		my ($sheetid, @excelcontent, %columnpos); #metadata excel
		printerr "JOB:\t Importing Sample Information from excel file => $file2consider\n"; #status    
    		@excelcontent = excelcontent($file2consider); #get excel content
		for (@excelcontent){s/%%//g;}
		foreach (@excelcontent) {
			my @array = split "\n";
			my @header = split('\?abc\?',lc($array[1]));
			if ($array[0] =~ /person/) { #Working with Person Sheet;
				undef %columnpos; #undefined column position
				if ($#array > 1) {
					foreach my $no (0..$#header) {
						$columnpos{$header[$no]} = $no;
					}#end foreach : put header info into a Dictionary
					foreach my $ne (2..$#array) {
						my @value = split('\?abc\?', $array[$ne]);
						if (length $value[0] > 1) {
							$sheetid  = "$value[$columnpos{'person first name'}] $value[$columnpos{'person initials'}] $value[$columnpos{'person last name'}]";
							$sth = $dbh->prepare("select personid from Person where personid = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
							unless ($found) { # if person is not in the database
								$sth = $dbh->prepare("insert into Person (personid, lastname, middleinitial, firstname, email, role) values (?,?,?,?,?,?)");
								$sth->execute($sheetid, $value[$columnpos{'person last name'}], $value[$columnpos{'person initials'}], $value[$columnpos{'person first name'}], $value[$columnpos{'person email'}], $value[$columnpos{'person role'}]) or die "\nERROR:\t Complication in Person table\n";
							}
							$NAME{$sheetid} = $sheetid;
						} else { #end if : insert into database
							undef $sheetid;
						} #end else table has no information
					} #end foreach : getting information into the database and into dictionary
				} else { #end if : if there is content in thetable
					undef $sheetid; #make sure sheetid is undefined if there is no content in the sheet
				}
			}
			if ($array[0] =~ /organization/)  { #Working with Organization Sheet;
				undef %columnpos; #undefine column position
				if ($#array > 1) {
					foreach my $no (0..$#header) {
						$columnpos{$header[$no]} = $no;
					}#end foreach : put header info into a Dictionary
					foreach my $ne (2..$#array) {
						my @value = split('\?abc\?', $array[$ne]);
						if (length $value[0] > 1) {
							$sheetid  = $value[$columnpos{'organization name'}];
							$sth = $dbh->prepare("select organizationname from Organization where organizationname = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
							unless ($found) { # if organization is not in the database
								$sth = $dbh->prepare("insert into Organization (organizationname,address, URL, role) values (?,?,?,?)");
								$sth->execute($sheetid, $value[$columnpos{'organization address'}], $value[$columnpos{'organization uri'}], $value[$columnpos{'organization role'}]) or die "\nERROR:\t Complication in Organization table\n";
							} 
							$ORGANIZATION{$sheetid} = $sheetid;
						} else { #end if : insert into database
							undef $sheetid;
						} #end else table has no information
					} #end foreach : getting information into the database and into dictionary
				} else { #end if : if there is content in thetable
					undef $sheetid; #make sure sheetid is undefined if there is no content in the sheet
				} #end else
			} #end if organization
			if ($array[0] =~ /animal/)  { #Working with Animal Sheet;
				my %ANIMAL = (material=>'Material', organism => 'Organism', sex => 'Sex', breed => 'Breed');
				undef %columnpos; #undefine column position
				if ($#array > 1) {
					foreach my $no (0..$#header) {
						if ($header[$no] =~ /[material|organism|sex|breed|health]/) {
							$columnpos{$header[$no]} = $no;
							$no = $no+2;
						} elsif ($header[$no] =~ /[birth|placental|pregnancy]/) {
							$columnpos{$header[$no]} = $no;
							$no = $no+2;
						} else {
							$columnpos{$header[$no]} = $no;
						}
					}	#end foreach : put header info into a Dictionary
					foreach my $ne (2..$#array) {
						my @value = split('\?abc\?', $array[$ne]);
						if (length $value[0] > 1) {
							foreach my $id (sort keys %ANIMAL) { 
								if (length $value[$columnpos{$id}] > 1) {
									$sheetid  = "$value[$columnpos{$id}]";
									my $loc = $columnpos{$id};
									$sth = $dbh->prepare("select $id from $ANIMAL{$id} where $id = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
									unless ($found) { # if material is not in the database
										$sth = $dbh->prepare("insert into $ANIMAL{$id} ($id, termref, termid) values (?,?,?)");
										$sth->execute($sheetid, $value[$loc+1], $value[$loc+2] ) or die "\nERROR:\t Complication in $ANIMAL{$id} table\n";
									}
								}
							}
							if (length $value[$columnpos{'health status'}] > 1) {
								$sheetid  = "$value[$columnpos{'health status'}]";
								my $loc = $columnpos{'health status'};
								$sth = $dbh->prepare("select health from HealthStatus where health = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
								unless ($found) { # if material is not in the database
									$sth = $dbh->prepare("insert into HealthStatus (health,termref, termid) values (?,?,?)");
									$sth->execute($sheetid, $value[$loc+1], $value[$loc+2] ) or die "\nERROR:\t Complication in HealthStatus table\n";
								}
							}
							$sheetid  = uc($value[$columnpos{'sample name'}]); #Animal Table
							$sth = $dbh->prepare("select animalid from Animal where animalid = '$sheetid'"); $sth->execute(); $found =$sth->fetch();
							unless ($found) { # if animal is not in the database
								printerr "NOTICE:\t Importing $sheetid to Animal table\n";
								$sth = $dbh->prepare("insert into Animal (animalid, project, material, organism, sex, health, breed, description) values (?,?,?,?,?,?,?,?)");
								$sth->execute($sheetid, $value[$columnpos{'project'}], $value[$columnpos{'material'}], $value[$columnpos{'organism'}], $value[$columnpos{'sex'}], $value[$columnpos{'health status'}], $value[$columnpos{'breed'}],$value[$columnpos{'sample description'}]) or die "\nERROR:\t Complication in Animal table\n";
							} else {
								$verbose and printerr "Duplicate: AnimalID '$sheetid' already exists in Animal table. Moving on\n";
							}
							$sth = $dbh->prepare("select animalid from AnimalStats where animalid = '$sheetid'"); $sth->execute(); $found =$sth->fetch();
							unless ($found) { # if animalstats is not in the database
								my ($loc, $birthdate, $birthlocation, $birthloclatitude, $birthloclongitude, $birthweight, $placentaweight, $pregnancylength) = ();
								if ($value[$columnpos{'birth date'}]) { $birthdate = "$value[$columnpos{'birth date'}] \($value[$columnpos{'birth date'}+1]\)"; }
								if ($value[$columnpos{'birth location'}]) { $birthlocation = "$value[$columnpos{'birth location'}] \($value[$columnpos{'birth location'}+1]\)"; }
								if ($value[$columnpos{'birth location latitude'}]) { $birthloclatitude = "$value[$columnpos{'birth location latitude'}] \($value[$columnpos{'birth location latitude'}+1]\)"; }
								if ($value[$columnpos{'birth location longitude'}]) { $birthloclongitude = "$value[$columnpos{'birth location longitude'}] \($value[$columnpos{'birth location longitude'}+1]\)"; }
								if ($value[$columnpos{'birth weight'}]) { $birthweight = "$value[$columnpos{'birth weight'}] \($value[$columnpos{'birth weight'}+1]\)"; }
								if ($value[$columnpos{'placental weight'}]) { $placentaweight = "$value[$columnpos{'placental weight'}] \($value[$columnpos{'placental weight'}+1]\)"; }
								if ($value[$columnpos{'pregnancy length'}]) { $pregnancylength = "$value[$columnpos{'pregnancy length'}] \($value[$columnpos{'pregnancy length'}+1]\)"; }
								$sth = $dbh->prepare("insert into AnimalStats (animalid, birthdate, birthlocation, birthloclatitude, birthloclongitude, birthweight, placentalweight, pregnancylength, deliveryease, deliverytiming, pedigree) values (?,?,?,?,?,?,?,?,?,?,?)");
								$sth->execute($sheetid, $birthdate, $birthlocation, $birthloclatitude, $birthloclongitude, $birthweight, $placentaweight, $pregnancylength, $value[$columnpos{'delivery ease'}], $value[$columnpos{'delivery timing'}], $value[$columnpos{'pedigree'}]) or die "\nERROR:\t Complication in AnimalStats table\n";
							} else {
								$verbose and printerr "Duplicate: AnimalID '$sheetid' already exists in AnimalStats table. Moving on\n";
							}							
						} else { #end if : insert into database
							undef $sheetid;
						} #end else table has no information
					} #end foreach : getting information into the database
				} else { #end if : if there is content in thetable
					undef $sheetid; #make sure sheetid is undefined if there is no content in the sheet
				} #end else
			} #end if animal
			if ($array[0] =~ /specimen/)  { #Working with Specimen Sheet;
				undef %columnpos; #undefine column position
				if ($#array > 1) {
					foreach my $no (0..$#header) {
						if ($header[$no] =~ /[material|organism|health|developmental]/) {
							$columnpos{$header[$no]} = $no;
							$no = $no+2;
						} elsif ($header[$no] =~ /[date|animal age|number|volume|size|weight|gestational]/) {
							$columnpos{$header[$no]} = $no;
							$no = $no+2;
						} else {
							$columnpos{$header[$no]} = $no;
						}
					}	#end foreach : put header info into a Dictionary
					foreach my $ne (2..$#array) { #each row
						my @value = split('\?abc\?', $array[$ne]);
						if (length $value[0] > 1) {
							if (length $value[$columnpos{'material'}] > 1) {
								$sheetid  = "$value[$columnpos{'material'}]";
								my $loc = $columnpos{'material'};
								$sth = $dbh->prepare("select material from Material where material = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
								unless ($found) { # if material is not in the database
									$sth = $dbh->prepare("insert into Material (material,termref, termid) values (?,?,?)");
									$sth->execute($sheetid, $value[$loc+1], $value[$loc+2] ) or die "\nERROR:\t Complication in Material table\n";
								}
							}
							if (length $value[$columnpos{'organism part'}] > 1) {
								$value[$columnpos{'organism part'}] = lc($value[$columnpos{'organism part'}]);
								$sheetid  = "$value[$columnpos{'organism part'}]"; 
								my $loc = $columnpos{'organism part'};
								$sth = $dbh->prepare("select tissue from Tissue where tissue = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
								unless ($found) { # if is not in the database
									$sth = $dbh->prepare("insert into Tissue (tissue,termref, termid) values (?,?,?)");
									$sth->execute($sheetid, $value[$loc+1], $value[$loc+2] ) or die "\nERROR:\t Complication in Tissue table\n";
								}
							}
							if (length $value[$columnpos{'developmental stage'}] > 1) {
								$sheetid  = "$value[$columnpos{'developmental stage'}]";
								my $loc = $columnpos{'developmental stage'};
								$sth = $dbh->prepare("select developmentalstage from DevelopmentalStage where developmentalstage = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
								unless ($found) { # ifis not in the database
									$sth = $dbh->prepare("insert into DevelopmentalStage (developmentalstage,termref, termid) values (?,?,?)");
									$sth->execute($sheetid, $value[$loc+1], $value[$loc+2] ) or die "\nERROR:\t Complication in DevelopmentalStage table\n";
								}
							}
							if (length $value[$columnpos{'health status at collection'}] > 1) {
								$sheetid  = "$value[$columnpos{'health status at collection'}]";
								my $loc = $columnpos{'health status at collection'};
								$sth = $dbh->prepare("select health from HealthStatus where health = '$sheetid'"); $sth->execute(); $found = $sth->fetch();
								unless ($found) { # if is not in the database
									$sth = $dbh->prepare("insert into HealthStatus (health,termref, termid) values (?,?,?)");
									$sth->execute($sheetid, $value[$loc+1], $value[$loc+2] ) or die "\nERROR:\t Complication in HealthStatus table\n";
								}
							}
							$sheetid  = uc($value[$columnpos{'sample name'}]); #Sample Table
							$sth = $dbh->prepare("select sampleid from Sample where sampleid = '$sheetid'"); $sth->execute(); $found =$sth->fetch();
							unless ($found) { # if sample is not in the database
								printerr "NOTICE:\t Importing $sheetid to Sample table\n";
								$sth = $dbh->prepare("insert into Sample (sampleid, project, material, tissue, derivedfrom, availability, developmentalstage, health, description, date) values (?,?,?,?,?,?,?,?,?,?)");
								$sth->execute($sheetid, $value[$columnpos{'project'}], $value[$columnpos{'material'}], $value[$columnpos{'organism part'}], uc($value[$columnpos{'derived from'}]), $value[$columnpos{'availability'}], $value[$columnpos{'developmental stage'}], $value[$columnpos{'health status at collection'}],$value[$columnpos{'sample description'}], $date) or die "\nERROR:\t Complication in Sample table\n";
							} else {
								printerr "Duplicate: SampleID '$sheetid' already exists in Sample table. Moving on\n";
								printerr "Optional: To delete $sheetid ; Execute: tad-import.pl -delete $sheetid\n";
							}
							$sth = $dbh->prepare("select sampleid from SampleStats where sampleid = '$sheetid'"); $sth->execute(); $found =$sth->fetch();
							unless ($found) { # if samplestats is not in the database
								my ($specimendate, $agecollect, $noofpieces, $specimenvolume, $specimensize, $specimenweight, $gestage) = ();
								if ($value[$columnpos{'specimen collection date'}]) { $specimendate = "$value[$columnpos{'specimen collection date'}] \($value[$columnpos{'specimen collection date'}+1]\)"; }
								if ($value[$columnpos{'animal age at collection'}]) { $agecollect = "$value[$columnpos{'animal age at collection'}] \($value[$columnpos{'animal age at collection'}+1]\)"; }
								if ($value[$columnpos{'number of pieces'}]) { $noofpieces = "$value[$columnpos{'number of pieces'}] \($value[$columnpos{'number of pieces'}+1]\)"; }
								if ($value[$columnpos{'specimen volume'}]) { $specimenvolume = "$value[$columnpos{'pecimen volume'}] \($value[$columnpos{'pecimen volume'}+1]\)"; }
								if ($value[$columnpos{'specimen size'}]) { $specimensize = "$value[$columnpos{'specimen size'}] \($value[$columnpos{'specimen size'}+1]\)"; }
								if ($value[$columnpos{'specimen weight'}]) { $specimenweight = "$value[$columnpos{'specimen weight'}] \($value[$columnpos{'specimen weight'}+1]\)"; }
								if ($value[$columnpos{'gestational age at sample collection'}]) { $gestage = "$value[$columnpos{'gestational age at sample collection'}] \($value[$columnpos{'gestational age at sample collection'}+1]\)"; }
								$sth = $dbh->prepare("insert into SampleStats (sampleid, collectionprotocol, collectiondate, ageatcollection, fastedstatus, noofpieces, specimenvol, specimensize, specimenwgt, specimenpictureurl, gestationalage) values (?,?,?,?,?,?,?,?,?,?,?)");
								$sth->execute($sheetid, $value[$columnpos{'specimen collection protocol'}], $specimendate, $agecollect, $value[$columnpos{'fasted status'}], $noofpieces, $specimenvolume, $specimensize, $specimenweight, $value[$columnpos{'specimen picture url'}], $gestage) or die "\nERROR:\t Complication in SampleStats table\n";
							} else {
								$verbose and printerr "Duplicate: SampleID '$sheetid' already exists in SampleStats table. Moving on\n";
							}
							foreach (keys %NAME) {
								$sth = $dbh->prepare("select sampleid, personid from SamplePerson where sampleid = '$sheetid' and personid = '$_'"); $sth->execute(); $found =$sth->fetch();
								unless ($found) { # if sample-person is not in the database
									$sth = $dbh->prepare("insert into SamplePerson (sampleid, personid) values (?,?)");
									$sth->execute($sheetid, $_) or die "\nERROR:\t Complication in SamplePerson table\n";
								}
							}
							foreach (keys %ORGANIZATION) {
								$sth = $dbh->prepare("select sampleid, organizationname from SampleOrganization where sampleid = '$sheetid' and organizationname = '$_'"); $sth->execute(); $found =$sth->fetch();
								unless ($found) { # if sample-organization is not in the database
									$sth = $dbh->prepare("insert into SampleOrganization (sampleid, organizationname) values (?,?)");
									$sth->execute($sheetid, $_) or die "\nERROR:\t Complication in SampleOrganization table\n";
								}
							}
						} else { #end if : insert into database
							undef $sheetid;
						} #end else table has no information
					} #end foreach : getting information into the database
				} else { #end if : if there is content in thetable
					undef $sheetid; #make sure sheetid is undefined if there is no content in the sheet
				}#end else			
			} #end if specimen
		} #end foreach @excelcontent
  	} #end if excel
} #end if metadata

#PROCESSING DATA IMPORT
if ($datadb){
	printerr "JOB:\t Importing Transcriptome analysis Information => $file2consider\n"; #status
  if ($variant){
		printerr "TASK:\t Importing ONLY Variant Information => $file2consider\n"; #status
  } elsif ($all) {
    printerr "TASK:\t Importing BOTH Gene Expression profiling and Variant Information => $file2consider\n"; #status
  } else {
    printerr "TASK:\t Importing ONLY Gene Expression Profiling information => $file2consider\n"; #status
  }
  $dbh = mysql($all_details{"MySQL-databasename"}, $all_details{'MySQL-username'}, $all_details{'MySQL-password'}); #connect to mysql
  my $dataid = (split("\/", $file2consider))[-1]; 
  `find $file2consider` or pod2usage ("ERROR: Can not locate \"$file2consider\"");
  opendir (DIR, $file2consider) or pod2usage ("Error: $file2consider is not a folder, please specify your sample directory location "); close (DIR);
  my @foldercontent = split("\n", `find $file2consider -type f -print0 | xargs -0 ls -tr `); #get details of the folder
		
  foreach (grep /\.gtf/, @foldercontent) { unless (`head -n 3 $_ | wc -l` <= 0 && $_ =~ /skipped/) { $transcriptsgtf = $_; } }
	$alignfile = (grep /summary.txt/, @foldercontent)[0];
  $genesfile = (grep /genes.fpkm/, @foldercontent)[0];
  $deletionsfile = (grep /deletions.bed/, @foldercontent)[0];
  $insertionsfile = (grep /insertions.bed/, @foldercontent)[0];
  $junctionsfile = (grep /junctions.bed/, @foldercontent)[0];
	$bamfile = (grep /.bam$/, @foldercontent)[0];
  $variantfile = (grep /.vcf$/, @foldercontent)[0]; 
  $vepfile = (grep /.vep.txt$/, @foldercontent)[0];
  $annofile = (grep /anno.txt$/, @foldercontent)[0];
	$readcountfile = (grep /.counts$/, @foldercontent)[0];
	$kallistofile = (grep /.tsv$/, @foldercontent)[0];
	$kallistologfile = (grep /run_info.json/, @foldercontent)[0];
	$salmonfile = (grep /.sf$/, @foldercontent)[0];
	$salmonlogfile = (grep /cmd_info.json$/, @foldercontent)[0];

  $sth = $dbh->prepare("select sampleid from Sample where sampleid = '$dataid'"); $sth->execute(); $found = $sth->fetch();
  if ($found) { # if sample is not in the database    
    $sth = $dbh->prepare("select sampleid from MapStats where sampleid = '$dataid'"); $sth->execute(); $found = $sth->fetch();
    LOGFILE();
		unless ($found) { 
			#open alignment summary file
      unless ($kallistologfile || $salmonlogfile) {
				if ($alignfile) {
					`head -n 1 $alignfile` =~ /^(\d+)\sreads/; $total = $1;
					open(ALIGN,"<", $alignfile) or die "\nFAILED:\t Can not open Alignment summary file '$alignfile'\n";
					while (<ALIGN>){
						chomp;
						if (/Input/){my $line = $_; $line =~ /Input.*:\s+(\d+)$/;$total = $1;}
						if (/overall/) { my $line = $_; $line =~ /^(\d+.\d+)%\s/; $alignrate = $1;}
						if (/overall read mapping rate/) {
							if ($mappingtool){
								unless ($mappingtool =~ /TopHat/i){
									die "\nERROR:\t Inconsistent Directory Structure, $mappingtool SAM file with TopHat align_summary.txt file found\n";
								}
							} else { $mappingtool = "TopHat"; }
						}
						if (/overall alignment rate/) {
							if ($mappingtool){
								unless ($mappingtool =~ /hisat/i){
									die "\nERROR:\t Inconsistent Directory Structure, $mappingtool LOG file with HISAT align_summary.txt file found\n";
								}
							} else { $mappingtool = "HISAT";}
						}
					} close ALIGN;
					$mapped = ceil($total * $alignrate/100);
				} else {die "\nFAILED:\t Can not find Alignment summary file as 'align_summary.txt'\n";}
			}
     				
			$deletions = undef; $insertions = undef; $junctions = undef;
			if ($deletionsfile){ $deletions = `cat $deletionsfile | wc -l`; $deletions--; } 
			if ($insertionsfile){ $insertions = `cat $insertionsfile | wc -l`; $insertions--; }
			if ($junctionsfile){ $junctions = `cat $junctionsfile | wc -l`; $junctions--; }
						
			#INSERT INTO DATABASE:
			#MapStats table
			if ($mappingtool) { printerr "NOTICE:\t Importing $mappingtool alignment information for $dataid to MapStats table ..."; }
			$sth = $dbh->prepare("insert into MapStats (sampleid, totalreads, mappedreads, alignmentrate, deletions, insertions, junctions, date ) values (?,?,?,?,?,?,?,?)");
			$sth ->execute($dataid, $total, $mapped, $alignrate, $deletions, $insertions, $junctions, $date) or die "\nERROR:\t Complication in MapStats table, consult documentation\n";
			if ($mappingtool) { printerr " Done\n"; }
			#metadata table
			if ($mappingtool) { printerr "NOTICE:\t Importing $mappingtool alignment information for $dataid to Metadata table ..."; }
			$sth = $dbh->prepare("insert into Metadata (sampleid, refgenome, annfile, stranded, sequencename, mappingtool ) values (?,?,?,?,?,?)");
			$sth ->execute($dataid, $refgenomename, $annotationfile, $stranded,$sequences, $mappingtool) or die "\nERROR:\t Complication in Metadata table, consult documentation\n";
			
			#Insert DataSyntaxes
			if ($mparameters) {
				$sth = $dbh->prepare("insert into CommandSyntax (sampleid, mappingsyntax ) values (?,?)");
				$mparameters =~ s/\"//g;
				$sth ->execute($dataid, $mparameters) or die "\nERROR:\t Complication in CommandSyntax table, consult documentation\n";
			}
			if ($mappingtool) { printerr " Done\n"; }

			#toggle options
			unless ($variant) {
				GENES_FPKM($dataid);
				READ_COUNT($dataid);
				if ($all){
					DBVARIANT($variantfile, $dataid);
					printerr " Done\n";
					#variant annotation specifications
					if ($vep) {
						printerr "TASK:\t Importing Variant annotation from VEP => $file2consider\n"; #status
						printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
						VEPVARIANT($vepfile, $dataid); printerr " Done\n";
						NOSQL($dataid);
					}
					if ($annovar) {
						printerr "TASK:\t Importing Variant annotation from ANNOVAR => $file2consider\n"; #status
						printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
						ANNOVARIANT($annofile, $dataid); printerr " Done\n";
						NOSQL($dataid);
					}
				}
			}
			else { #variant option selected
				DBVARIANT($variantfile, $dataid);
				printerr " Done\n";
				#variant annotation specifications
				if ($vep) {
					printerr "TASK:\t Importing Variant annotation from VEP => $file2consider\n"; #status
					printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
					VEPVARIANT($vepfile, $dataid); printerr " Done\n";
					NOSQL($dataid);
				}
				if ($annovar) {
					printerr "TASK:\t Importing Variant annotation from ANNOVAR => $file2consider\n"; #status
					printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
					ANNOVARIANT($annofile, $dataid); printerr " Done\n";
					NOSQL($dataid);
				}
			}
		} else { #end unless found in MapStats table
			printerr "NOTICE:\t $dataid already in MapStats table... Moving on \n";
			$additional .=  "Optional: To delete '$dataid' Alignment information ; Execute: tad-import.pl -delete $dataid \n";
			$sth = $dbh->prepare("select sampleid from Metadata where sampleid = '$dataid'"); $sth->execute(); $found = $sth->fetch();
			unless ($found) {
				printerr "NOTICE:\t Importing $mappingtool alignment information for $dataid to Metadata table ...";
				$sth = $dbh->prepare("insert into Metadata (sampleid, refgenome, annfile, stranded, sequencename, mappingtool) values (?,?,?,?,?,?)");
				$sth ->execute($dataid, $refgenomename, $annotationfile, $stranded,$sequences, $mappingtool) or die "\nERROR:\t Complication in Metadata table, consult documentation\n";
				
				#Insert DataSyntaxes
				$sth = $dbh->prepare("insert into CommandSyntax (sampleid, mappingsyntax ) values (?,?)");
				$mparameters =~ s/\"//g;
				$sth ->execute($dataid, $mparameters) or die "\nERROR:\t Complication in CommandSyntax table, consult documentation\n";
				printerr " Done\n";
				
			} #end else found in MapStats table
			#toggle options
			unless ($variant) {
				GENES_FPKM($dataid); #GENES
				READ_COUNT($dataid); #READCOUNTS
				if ($all){
					my $variantstatus = $dbh->selectrow_array("select status from VarSummary where sampleid = '$dataid' and status = 'done'");
					unless ($variantstatus){ #checking if completed in VarSummary table
						$verbose and printerr "NOTICE:\t Removed incomplete records for $dataid in all Variants tables\n";
						$sth = $dbh->prepare("delete from VarAnnotation where sampleid = '$dataid'"); $sth->execute();
						$sth = $dbh->prepare("delete from VarResult where sampleid = '$dataid'"); $sth->execute();
						$sth = $dbh->prepare("delete from VarSummary where sampleid = '$dataid'"); $sth->execute();
						DBVARIANT($variantfile, $dataid);
						printerr " Done\n";
						#variant annotation specifications
						if ($vep) {
								printerr "TASK:\t Importing Variant annotation from VEP => $file2consider\n"; #status
								printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
								VEPVARIANT($vepfile, $dataid); printerr " Done\n";
								NOSQL($dataid);
						}
						if ($annovar) {
								printerr "TASK:\t Importing Variant annotation from ANNOVAR => $file2consider\n"; #status
								printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
								ANNOVARIANT($annofile, $dataid); printerr " Done\n";
								NOSQL($dataid);
						}
					} else {
						printerr "NOTICE:\t $dataid already in VarResult table... Moving on \n";
						if ($vep || $annovar) {
							my $variantstatus = $dbh->selectrow_array("select annversion from VarSummary where sampleid = '$dataid'");
							my $nosqlstatus = $dbh->selectrow_array("select nosql from VarSummary where sampleid = '$dataid'");
							unless ($variantstatus && $nosqlstatus){ #if annversion or nosqlstatus is not specified
								$verbose and printerr "NOTICE:\t Removed incomplete records for $dataid in VarAnnotation table\n";
								$sth = $dbh->prepare("delete from VarAnnotation where sampleid = '$dataid'"); $sth->execute();
								if ($vep) {
									printerr "TASK:\t Importing Variant annotation from VEP => $file2consider\n"; #status
									printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
									VEPVARIANT($vepfile, $dataid); printerr " Done\n";
									NOSQL($dataid);
								}
								if ($annovar) {
									printerr "TASK:\t Importing Variant annotation from ANNOVAR => $file2consider\n"; #status
									printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
									ANNOVARIANT($annofile, $dataid); printerr " Done\n";
									NOSQL($dataid);
								}
							} else { #end unless annversion is previously specified
								printerr "NOTICE:\t $dataid already in VarAnnotation table... Moving on\n";
							}
						} #end if annversion is previously specified
							$additional .=  "Optional: To delete '$dataid' Variant information ; Execute: tad-import.pl -delete $dataid \n";
					} #end unless it's already in variants table
        } #end if "all" option
	    } #end unless default option is specified 
      else { #variant option selected
        my $variantstatus = $dbh->selectrow_array("select status from VarSummary where sampleid = '$dataid' and status = 'done'");
        unless ($variantstatus){ #checking if completed in VarSummary table
					$verbose and printerr "NOTICE:\t Removed incomplete records for $dataid in all Variants tables\n";
					$sth = $dbh->prepare("delete from VarAnnotation where sampleid = '$dataid'"); $sth->execute();
					$sth = $dbh->prepare("delete from VarResult where sampleid = '$dataid'"); $sth->execute();
					$sth = $dbh->prepare("delete from VarSummary where sampleid = '$dataid'"); $sth->execute();
					DBVARIANT($variantfile, $dataid);
					printerr " Done\n";
					#variant annotation specifications
					if ($vep) {
						printerr "TASK:\t Importing Variant annotation from VEP => $file2consider\n"; #status
						printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
						VEPVARIANT($vepfile, $dataid); printerr " Done\n";
						NOSQL($dataid);
					}
					if ($annovar) {
						printerr "TASK:\t Importing Variant annotation from ANNOVAR => $file2consider\n"; #status
						printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
						ANNOVARIANT($annofile, $dataid); printerr " Done\n";
						NOSQL($dataid);
					}
				} else { #if completed in VarSummary table
					printerr "NOTICE:\t $dataid already in VarResult table... Moving on \n";
					if ($vep || $annovar) { #checking if vep or annovar was specified
						my $variantstatus = $dbh->selectrow_array("select annversion from VarSummary where sampleid = '$dataid'");
						my $nosqlstatus = $dbh->selectrow_array("select nosql from VarSummary where sampleid = '$dataid'");
						unless ($variantstatus && $nosqlstatus){ #if annversion or nosqlstatus is not specified
							$verbose and printerr "NOTICE:\t Removed incomplete records for $dataid in all Variant Annotation tables\n";
							$sth = $dbh->prepare("delete from VarAnnotation where sampleid = '$dataid'"); $sth->execute();
							if ($vep) {
								printerr "TASK:\t Importing Variant annotation from VEP => $file2consider\n"; #status
								printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
								VEPVARIANT($vepfile, $dataid); printerr " Done\n";
								NOSQL($dataid);
							}
							if ($annovar) {
								printerr "TASK:\t Importing Variant annotation from ANNOVAR => $file2consider\n"; #status
								printerr "NOTICE:\t Importing $dataid - Variant Annotation to VarAnnotation table ...";
								ANNOVARIANT($annofile, $dataid); printerr " Done\n";
								NOSQL($dataid);
							}
						} else { #end unless annversion is previously specified
							printerr "NOTICE:\t $dataid already in VarAnnotation table... Moving on \n";
						}
					} #end if annversion is previously specified
					$additional .=  "Optional: To delete '$dataid' Variant information ; Execute: tad-import.pl -delete $dataid \n";
				} # end else already in VarSummary table;
			} #end if "variant" option
		} #unless & else exists in Mapstats
	} else {
		pod2usage("FAILED: \"$dataid\" sample information is not in the database. Make sure the metadata has be previously imported using '-metadata'");
	} #end if data in sample table
}

if ($delete){ #delete section
	my (%KEYDELETE, $decision);
	my ($i,$alldelete) = (0,0);
	unless ($log) { printerr "JOB:\t Deleting Existing Records in Database\n"; } #status
	$dbh = mysql($all_details{'MySQL-databasename'}, $all_details{'MySQL-username'}, $all_details{'MySQL-password'}); #connect to mysql
  	$sth = $dbh->prepare("select sampleid from Sample where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
	if ($found) {
		unless ($log) { printerr "NOTICE:\t This module deletes records from ALL database systems for TransAtlasDB. Proceed with caution\n"; }
		$sth = $dbh->prepare("select sampleid from Sample where sampleid = '$delete'"); $sth->execute(); $found =$sth->fetch();
    		if ($found) {
			$i++; $KEYDELETE{$i} = "Sample Information";
		}
		$sth = $dbh->prepare("select sampleid from MapStats where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
    		if ($found) {
			$i++; $KEYDELETE{$i} = "Alignment Information";
		}
		$sth = $dbh->prepare("select sampleid from GeneStats where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
    		if ($found) {
			$i++; $KEYDELETE{$i} = "Expression Information";
		}
		$sth = $dbh->prepare("select sampleid from VarSummary where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
    		if ($found) {
			$i++; $KEYDELETE{$i} = "Variant Information";
		}
		unless ($log) {
			print "--------------------------------------------------------------------------\n";
    		print "The following details match the sampleid '$delete' provided\n";
    		foreach (sort {$a <=> $b} keys %KEYDELETE) { print "  ", uc($_),"\.  $KEYDELETE{$_}\n";}
		}
		$KEYDELETE{0} = "ALL information relating to '$delete'";
		unless ($log) {
			print "  0\.  ALL information relating to '$delete'\n";
			print "--------------------------------------------------------------------------\n";
			print "Choose which information you want remove (multiple options separated by comma) or press ENTER to leave ? ";
			chomp ($decision = (<>)); print "\n";
		} else {$decision = $log; }
		if (length $decision >0) {
			my @allverdict = split(",",$decision);
			foreach my $verdict (sort {$b<=>$a} @allverdict) {
				if (exists $KEYDELETE{$verdict}) {
					printerr "NOTICE:\t Deleting $KEYDELETE{$verdict}\n";
					if ($verdict == 0) {$alldelete = 1;}
					if ($KEYDELETE{$verdict} =~ /^Variant/ || $alldelete == 1) {
						if ($alldelete == 1){
							if ($KEYDELETE{$i} =~ /^Variant/) { $i--;
								my $ffastbit = fastbit($all_details{'FastBit-path'}, $all_details{'FastBit-foldername'});  #connect to fastbit
								my $vfastbit = $ffastbit."/variant-information"; # specifying the variant section.
								printerr "NOTICE:\t Deleting records for $delete in Variant tables ";
								$sth = $dbh->prepare("delete from VarAnnotation where sampleid = '$delete'"); $sth->execute(); printerr ".";
								$sth = $dbh->prepare("delete from VarResult where sampleid = '$delete'"); $sth->execute(); printerr ".";
								$sth = $dbh->prepare("delete from VarSummary where sampleid = '$delete'"); $sth->execute(); printerr ".";
								my $execute = "$ibis -d $vfastbit -y \"sampleid = '$delete'\" -z";
								`$execute 2>> $efile`; printerr ".";
								`rm -rf $vfastbit/*sp $vfastbit/*old $vfastbit/*idx $vfastbit/*dic $vfastbit/*int `; #removing old indexes
								`ibis -d $vfastbit -query "select genename, geneid, genetype, transcript, feature, codonchange, aachange, sampleid, chrom, tissue, organism, consequence, dbsnpvariant, source" 2>> $efile`; #create a new index based on genename
								printerr " Done\n";
							}
						} else {
							my $ffastbit = fastbit($all_details{'FastBit-path'}, $all_details{'FastBit-foldername'});  #connect to fastbit
							my $vfastbit = $ffastbit."/variant-information"; # specifying the variant section.
							printerr "NOTICE:\t Deleting records for $delete in Variant tables ";
							$sth = $dbh->prepare("delete from VarAnnotation where sampleid = '$delete'"); $sth->execute(); printerr ".";
							$sth = $dbh->prepare("delete from VarResult where sampleid = '$delete'"); $sth->execute(); printerr ".";
							$sth = $dbh->prepare("delete from VarSummary where sampleid = '$delete'"); $sth->execute(); printerr ".";
							my $execute = "$ibis -d $vfastbit -y \"sampleid = '$delete'\" -z";
							`$execute 2>> $efile`; printerr ".";
							`rm -rf $vfastbit/*sp $vfastbit/*old $vfastbit/*idx $vfastbit/*dic $vfastbit/*int `; #removing old indexes
							`ibis -d $vfastbit -query "select genename, geneid, genetype, transcript, feature, codonchange, aachange, sampleid, chrom, tissue, organism, consequence, dbsnpvariant, source" 2>> $efile`; #create a new index
							printerr " Done\n";
						}
					}
					if ($KEYDELETE{$verdict} =~ /^Expression/ || $alldelete ==1 ) {
						if ($alldelete == 1){
							if ($KEYDELETE{$i} =~ /^Expression/) { $i--;
								my $ffastbit = fastbit($all_details{'FastBit-path'}, $all_details{'FastBit-foldername'});  #connect to fastbit
								my $gfastbit = $ffastbit."/gene-information"; # specifying the gene section.
								my $cfastbit = $ffastbit."/gene_count-information"; #specifying the gene count section
								
								printerr "NOTICE:\t Deleting records for $delete in Gene tables ";
								$sth = $dbh->prepare("delete from GeneStats where sampleid = '$delete'"); $sth->execute(); printerr ".";
							
								#deleting gene-information from fastbit
								my $execute = "$ibis -d -v $gfastbit -y \"sampleid = '$delete'\" -z";
								`$execute 2>> $efile`; printerr ".";
								`rm -rf $gfastbit/*sp $gfastbit/*old $gfastbit/*idx $gfastbit/*dic $gfastbit/*int `; #removing old indexes
								`ibis -d $gfastbit -query "select genename, geneid, sampleid, chrom, tissue, organism" 2>> $efile`; #create a new index based on genename
								
								#deleting gene_counts information from fastbit
								$execute = "$ibis -d -v $cfastbit -y \"sampleid = '$delete'\" -z";
								`$execute 2>> $efile`; printerr ".";
								`rm -rf $cfastbit/*sp $cfastbit/*old $cfastbit/*idx $cfastbit/*dic $cfastbit/*int `; #removing old indexes
								`ibis -d $cfastbit -query "select genename, geneid, sampleid, tissue, organism" 2>> $efile`; #create a new index based on genename
								
								printerr " Done\n";
							}
						} else {
							my $ffastbit = fastbit($all_details{'FastBit-path'}, $all_details{'FastBit-foldername'});  #connect to fastbit
							my $gfastbit = $ffastbit."/gene-information"; # specifying the gene section.
							my $cfastbit = $ffastbit."/gene_count-information"; #specifying the gene count section
								
							printerr "NOTICE:\t Deleting records for $delete in Gene tables ";
							$sth = $dbh->prepare("delete from GeneStats where sampleid = '$delete'"); $sth->execute(); printerr ".";
							
							#deleting gene-information from fastbit
							my $execute = "$ibis -d -v $gfastbit -y \"sampleid = '$delete'\" -z";
							`$execute 2>> $efile`; printerr ".";
							`rm -rf $gfastbit/*sp $gfastbit/*old $gfastbit/*idx $gfastbit/*dic $gfastbit/*int `; #removing old indexes
							`ibis -d $gfastbit -query "select genename, geneid, sampleid, chrom, tissue, organism" 2>> $efile`; #create a new index based on genename
								
							#deleting gene_counts information from fastbit
							$execute = "$ibis -d -v $cfastbit -y \"sampleid = '$delete'\" -z";
							`$execute 2>> $efile`; printerr ".";
							`rm -rf $cfastbit/*sp $cfastbit/*old $cfastbit/*idx $cfastbit/*dic $cfastbit/*int `; #removing old indexes
							`ibis -d $cfastbit -query "select genename, geneid, sampleid, tissue, organism" 2>> $efile`; #create a new index based on genename
								
							printerr " Done\n";
						}
					}
					if ($KEYDELETE{$verdict} =~ /^Alignment/ || $alldelete ==1 ) {
						if ($alldelete == 1){
							if ($KEYDELETE{$i} =~ /^Alignment/) { $i--;
								$sth = $dbh->prepare("select sampleid from GeneStats where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
								unless ($found) {
									$sth = $dbh->prepare("select sampleid from VarSummary where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
									unless ($found) {
										printerr "NOTICE:\t Deleting records for $delete in Mapping tables .";
										$sth = $dbh->prepare("delete from Metadata where sampleid = '$delete'"); $sth->execute(); printerr ".";
										$sth = $dbh->prepare("delete from CommandSyntax where sampleid = '$delete'"); $sth->execute(); printerr ".";
										$sth = $dbh->prepare("delete from MapStats where sampleid = '$delete'"); $sth->execute();  printerr ".";
										printerr " Done\n";
									} else { printerr "ERROR:\t Variant Information relating to '$delete' is in the database. Delete Variant Information first\n";}
								} else { printerr "ERROR:\t Expression Information Relating to '$delete' still present in the database. Delete Expression Information first\n";}
							}
						} else {
							$sth = $dbh->prepare("select sampleid from GeneStats where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
							unless ($found) {
								$sth = $dbh->prepare("select sampleid from VarSummary where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
								unless ($found) {
									printerr "NOTICE:\t Deleting records for $delete in Mapping tables .";
									$sth = $dbh->prepare("delete from Metadata where sampleid = '$delete'"); $sth->execute(); printerr ".";
									$sth = $dbh->prepare("delete from CommandSyntax where sampleid = '$delete'"); $sth->execute(); printerr ".";
									$sth = $dbh->prepare("delete from MapStats where sampleid = '$delete'"); $sth->execute();  printerr ".";
									printerr " Done\n";
								} else { printerr "ERROR:\t Variant Information relating to '$delete' is in the database. Delete Variant Information first\n";}
							} else { printerr "ERROR:\t Expression Information Relating to '$delete' still present in the database. Delete Expression Information first\n";}
						}
					}
					if ($KEYDELETE{$verdict} =~ /^Sample/ || $alldelete ==1 ) {
						if ($alldelete == 1){
							if ($KEYDELETE{$i} =~ /^Sample/) { $i--;
								$sth = $dbh->prepare("select sampleid from MapStats where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
								unless ($found) {
									$sth = $dbh->prepare("select sampleid from GeneStats where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
									unless ($found) {
										$sth = $dbh->prepare("select sampleid from VarSummary where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
										unless ($found) {
											printerr "NOTICE:\t Deleting records for $delete in Sample tables ";
											$sth = $dbh->prepare("delete from SampleStats where sampleid = '$delete'"); $sth->execute(); printerr ".";
											$sth = $dbh->prepare("delete from SampleOrganization where sampleid = '$delete'"); $sth->execute(); printerr ".";
											$sth = $dbh->prepare("delete from SamplePerson where sampleid = '$delete'"); $sth->execute(); printerr ".";
											$sth = $dbh->prepare("delete from Sample where sampleid = '$delete'"); $sth->execute();  printerr ".";
											printerr " Done\n";
										} else { printerr "ERROR:\t Variant Information for '$delete' is in the database. Delete Variant Information first\n"; }
									} else { printerr "ERROR:\t Expression Information for '$delete' still present in the database. Delete Expression Information first\n"; }
								} else { printerr "ERROR:\t Alignment Information for '$delete' is in the database. Delete Alignment Information first\n"; }
							}
						} else {
							$sth = $dbh->prepare("select sampleid from MapStats where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
							unless ($found) {
								$sth = $dbh->prepare("select sampleid from GeneStats where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
								unless ($found) {
									$sth = $dbh->prepare("select sampleid from VarSummary where sampleid = '$delete'"); $sth->execute(); $found = $sth->fetch();
									unless ($found) {
										printerr "NOTICE:\t Deleting records for $delete in Sample tables ";
										$sth = $dbh->prepare("delete from SampleStats where sampleid = '$delete'"); $sth->execute(); printerr ".";
										$sth = $dbh->prepare("delete from SampleOrganization where sampleid = '$delete'"); $sth->execute(); printerr ".";
										$sth = $dbh->prepare("delete from SamplePerson where sampleid = '$delete'"); $sth->execute(); printerr ".";
										$sth = $dbh->prepare("delete from Sample where sampleid = '$delete'"); $sth->execute();  printerr ".";
										printerr " Done\n";
									} else { printerr "ERROR:\t Variant Information for '$delete' is in the database. Delete Variant Information first\n"; }
								} else { printerr "ERROR:\t Expression Information for '$delete' still present in the database. Delete Expression Information first\n"; }
							} else { printerr "ERROR:\t Alignment Information for '$delete' is in the database. Delete Alignment Information first\n"; }
						}
					}
				} else { printerr "ERROR:\t $verdict is an INVALID OPTION\n"; }
			}
		} else {printerr "NOTICE:\t No Option selected\n";}
	} else {
		printerr "NOTICE:\t Information relating to '$delete' is not in the database. Good-bye\n";
	}
}
#output: the end
unless ($log) {
	printerr "-----------------------------------------------------------------\n";
	if ($metadata){
	  	printerr ("SUCCESS: Import of Sample Information in \"$file2consider\"\n");
	} #end if complete RNASeq metadata
	if ($datadb){
	  	printerr ("SUCCESS: Import of RNA Seq analysis information in \"$file2consider\"\n");
	} #end if completed RNASeq data2db
	printerr $additional;
	$transaction = "data to database import" if $datadb;
	$transaction = "METADATA IMPORT(s)" if $metadata;
	$transaction = "DELETE '$delete' activity" if $delete;
	printerr ("NOTICE:\t Summary of $transaction in log file $efile\n");
	printerr "-----------------------------------------------------------------\n";
	print LOG "TransAtlasDB Completed:\t", scalar(localtime),"\n";
	close (LOG);
} else { `rm -rf $efile`; }
#--------------------------------------------------------------------------------

sub processArguments {
	my @commandline = @ARGV;
  	GetOptions('verbose|v'=>\$verbose, 'help|h'=>\$help, 'man|m'=>\$man, 'metadata'=>\$metadata,
		'data2db'=>\$datadb, 'gene'=>\$gene, 'variant'=>\$variant, 'all'=>\$all, 'vep'=>\$vep,
		'annovar'=>\$annovar, 't|tab'=>\$tab, 'x|excel'=>\$excel, 'w=s'=>\$log, 'delete=s'=>\$delete ) or pod2usage ();

	$help and pod2usage (-verbose=>1, -exitval=>1, -output=>\*STDOUT);
  	$man and pod2usage (-verbose=>2, -exitval=>1, -output=>\*STDOUT);  
  
	pod2usage(-msg=>"ERROR:\t Invalid syntax specified, choose -metadata or -data2db or -delete.") unless ( $metadata || $datadb|| $delete);
	pod2usage(-msg=>"ERROR:\t Invalid syntax specified for @commandline.") if (($metadata && $datadb)||($vep && $annovar) || ($gene && $vep) || ($gene && $annovar) || ($gene && $variant));
	if ($vep || $annovar) {
		pod2usage(-msg=>"ERROR:\t Invalid syntax specified for @commandline, specify -variant.") unless (($variant && $annovar)||($variant && $vep) || ($all && $annovar) || ($all && $vep));
	}
  	@ARGV<=1 or pod2usage("Syntax error");
  	$file2consider = $ARGV[0];
  	
	$verbose ||=0;
	my $get = dirname(abs_path $0); #get source path
	$connect = $get.'/.connect.txt';
	#setup log file
	$efile = @{ open_unique("db.tad_status.log") }[1]; `rm -rf $efile`;
	$nosql = @{ open_unique(".nosqlimport.txt") }[1]; `rm -rf $nosql`;
	$vnosql = @{ open_unique(".nosqlvimport.txt") }[1]; `rm -rf $vnosql`;
	$gnosql = @{ open_unique(".nosqlgimport.txt") }[1]; `rm -rf $gnosql`;
	$cnosql = @{ open_unique(".nosqlcimport.txt") }[1]; `rm -rf $cnosql`;
	unless ($log) {
		open(LOG, ">>", $efile) or die "\nERROR:\t cannot write LOG information to log file $efile $!\n";
		print LOG "TransAtlasDB Version:\t",$VERSION,"\n";
		print LOG "TransAtlasDB Information:\tFor questions, comments, documentation, bug reports and program update, please visit $default \n";
		print LOG "TransAtlasDB Command:\t $0 @commandline\n";
		print LOG "TransAtlasDB Started:\t", scalar(localtime),"\n";
	}
}

sub LOGFILE { #subroutine for getting metadata
	if ($bamfile){
		my $headerdetails = `samtools view -H $bamfile | grep -m 1 "\@PG" | head -1`;
		$headerdetails =~ /\@PG\s*ID\:(\S*).*VN\:(\S*)\s*CL\:(.*)/;
		$mappingtool = $1." v".$2; $mparameters = $3;
		if ($mappingtool =~ /hisat/i) {
			$mparameters =~ /\-x\s(\w+)\s/;
			$refgenome = $1; #reference genome name
			$refgenomename = (split('\/', $refgenome))[-1];
			if ($mparameters =~ /-1/){ #paired-end reads
				$mparameters =~ /\-1\s(\S+)\s-2\s(\S+)"$/;
				my @nseq = split(",",$1); my @pseq = split(",",$2);
				foreach (@nseq){ $sequences .= ( (split('\/', $_))[-1] ).",";}
				foreach (@pseq){ $sequences .= ( (split('\/', $_))[-1] ).",";}
				chop $sequences;
			}
			elsif ($mparameters =~ /-U/){ #single-end reads
				$mparameters =~ /\-U\s(\S+)"$/;
				my @nseq = split(",",$1);
				foreach (@nseq){ $sequences .= ( (split('\/', $_))[-1] ).",";}
				chop $sequences;
			} #end if toggle for sequences
			$stranded = undef;
			$annotationfile = undef;
		} # end if working with hisat.
		elsif ($mappingtool =~ /tophat/i) {
			my $annotation; undef %ALL; my $no = 0;
			my @newgeninfo = split('\s', $mparameters);
			my $number = 1;
			while ($number <= $#newgeninfo) {
				unless ($newgeninfo[$number] =~ /-no-coverage-search/){
					if ($newgeninfo[$number] =~ /^\-/){
						my $old = $number++;
						$ALL{$newgeninfo[$old]} = $newgeninfo[$number];
					} else {
						unless (exists $ALL{$no}){
							$ALL{$no} = $newgeninfo[$number];
							$no++;
						}
					}
				}
				$number++;
			}
			unless ((exists $ALL{"-G"}) || (exists $ALL{"--GTF"})) {
				$annotationfile = undef;
			} else {
				if (exists $ALL{"-G"}){ $annotation = $ALL{"-G"} ; } else { $annotation = $ALL{"--GTF"};}
				$annotationfile = uc ( (split('\.',((split("\/", $annotation))[-1])))[-1] ); #(annotation file)
			}
			unless (exists $ALL{"--library-type"}) { $stranded = undef; } else { $stranded = $ALL{"--library-type"}; }
		
			$refgenome = $ALL{0}; my $seq = $ALL{1}; my $otherseq = $ALL{2};
			$refgenomename = (split('\/', $ALL{0}))[-1]; 
			unless(length($otherseq)<1){ #sequences
				$sequences = ( ( split('\/', $seq) ) [-1]).",". ( ( split('\/', $otherseq) ) [-1]);
			} else {
				$sequences = ( ( split('\/', $seq) ) [-1]);
			} #end if seq
		} # end if working with tophat
		else {
			$annotationfile = undef;
			$stranded = undef; $sequences = undef;
		}
	} # end if bamfile
	if ($kallistologfile){
		my $versionnumber = `cat $kallistologfile | grep "kallisto_version" | awk -F'":' '{print \$2}'`; $versionnumber =~ s/\"//g; $versionnumber = substr($versionnumber,0,-2);
		$diffexpress = "kallisto v$versionnumber";
		$gparameters = `cat $kallistologfile | grep "call" | awk -F'":' '{print \$2}'`; $gparameters =~ s/\"//g;
		$gparameters =~ /-i\s(\S+)/; $refgenome = $1; $refgenomename = (split('\/', $refgenome))[-1]; $annotationfile = $refgenomename;
		my @newgeninfo = split(/\s/, $gparameters);
		if ($gparameters =~ /--single/) {	
			$sequences = ( ( split('\/', ($newgeninfo[-1])) ) [-1]);
		} else { #paired end reads
			$sequences = ( ( split('\/', $newgeninfo[-1]) ) [-2]).",". ( ( split('\/', $newgeninfo[-1]) ) [-1]);
		}
		$stranded = undef; $sequences = undef; $mappingtool = undef;
	} # end if kallistologfile
	if ($salmonlogfile){
		my $versionnumber = `cat $salmonlogfile | grep "salmon_version" | awk -F'":' '{print \$2}'`; $versionnumber =~ s/\"//g; $versionnumber = substr($versionnumber,0,-2);
		$diffexpress = "salmon v$versionnumber";
		$gparameters = `cat $salmonlogfile`;
		$refgenome = `cat $salmonlogfile | grep "index" | awk -F'":' '{print \$2}'`; $refgenome =~ s/\"//g; $refgenome = substr($refgenome,0,-2);
		$refgenomename = (split('\/', $refgenome))[-1]; $annotationfile = $refgenomename;
		$sequences = `cat $salmonlogfile | grep "mate" | awk -F'":' '{print \$2}'`; $sequences =~ s/\"//g; $sequences = substr($sequences,0,-2);
		my @newgeninfo = split(/\n/, $sequences); $sequences = undef;
		foreach (@newgeninfo) { $sequences .= (( split('\/', ($_)) ) [-1]); }
		$stranded = undef; $sequences = undef; $mappingtool = undef;
	} #end if salmonlogfile
}

sub READ_COUNT { #subroutine for read counts
	#INSERT INTO DATABASE: #ReadCounts table
	if ($readcountfile) {
		my $readcount = 0;
		$sth = $dbh->prepare("select countstatus from GeneStats where sampleid = '$_[0]' and countstatus ='done'"); $sth->execute(); $found = $sth->fetch();
		unless ($found) {
			my $ffastbit = fastbit($all_details{'FastBit-path'}, $all_details{'FastBit-foldername'});  #connect to fastbit
			my $cfastbit = $ffastbit."/gene_count-information"; # specifying the gene section.
			`$ibis -d $cfastbit -q 'select count(sampleid) where sampleid = "$_[0]"' -o $nosql 2>>$efile`;
			open(IN,"<",$nosql);
			no warnings;
			chomp($readcount = <IN>);
			close (IN); `rm -rf $nosql`;
			
			#get the organism name and the tissue from the database
			my $species = $dbh->selectrow_array("select a.organism from Animal a join Sample b on a.animalid = b.derivedfrom where b.sampleid = '$_[0]'");
			my $tissue = $dbh->selectrow_array("select tissue from Sample where sampleid = '$_[0]'");			
				
			#get type of input
			open(READ, "<", $readcountfile) or die "\nERROR:\t Can not open file $readcountfile\n";
			my ($countpreamble, $checkforpreamble) = (0,0);
			open (NOSQL, ">$cnosql");
			while (<READ>) {
				chomp;
				my @allidgene = split("\t");
				my ($idgene, $idcount) = ($allidgene[0], $allidgene[-1]);
				if ($idgene =~ /^[a-zA-Z0-9]/) {
					if ($countpreamble == 0 || $countpreamble == 2) {
						$checkforpreamble = 1;
					}
					if ($checkforpreamble == 1) {
						print NOSQL "'$_[0]','$idgene','$species','$tissue',$idcount\n"; #to fastbit
					} 
				} else {
					if ($_ =~ /featurecounts/i) {
						my ($program, $command) = split(';');
						$counttool = (split(':', $program))[1];
						$cparameters = (split(':', $command))[1];
						$cparameters =~ s/\"//g;
					} elsif ($_ =~ /^_/) {
						$counttool = "htseqcount";
						$cparameters = NULL;
					}
				}
				$countpreamble++;
			} close (READ);
			close NOSQL; #end of nosql portion
			
			if ($readcount < $countpreamble && $readcount != 0) {
				$verbose and printerr "NOTICE:\t Removed incomplete records for $_[0] in ReadCounts table\n";
				`$ibis -d $cfastbit -y \"sampleid = '$_[0]'\" -z 2>> $efile`;
				`rm -rf $cfastbit/*sp $cfastbit/*old $cfastbit/*idx $cfastbit/*dic $cfastbit/*int `; #removing old indexes
			}	
			
			printerr "NOTICE:\t Importing $counttool raw counts information for $_[0] to ReadCounts table ...";
			#import into ReadCounts table;
			my $ffastbit = fastbit($all_details{'FastBit-path'}, $all_details{'FastBit-foldername'});  #connect to fastbit
			my $cfastbit = $ffastbit."/gene_count-information"; # specifying the gene section.
			my $execute = "$ardea -d $cfastbit -m 'sampleid:text,genename:text,organism:text,tissue:text,readcount:double' -t $cnosql";
			`$execute 2>> $efile` or die "\nERROR\t: Complication importing RawCounts information to FastBit, contact $AUTHOR\n";
			`rm -rf $cfastbit/*sp`; #removeing old indexes
			`ibis -d $cfastbit -query "select genename, geneid, sampleid, tissue, organism" 2>> $efile`; #create a new index based on genename
			`chmod 777 $cfastbit && rm -rf $cnosql`;
			
			$sth = $dbh->prepare("update GeneStats set countstool = '$counttool', countstatus = 'done' where sampleid= '$_[0]'"); $sth ->execute(); #updating GeneStats table.
			$sth = $dbh->prepare("update CommandSyntax set countsyntax = '$cparameters' where sampleid= '$_[0]'"); $sth ->execute(); #updating CommandSyntax table.
			printerr " Done \n";	
				
		} else { #found and completed
				printerr "NOTICE:\t $_[0] already in ReadCounts table... Moving on \n";
				$additional .=  "Optional: To delete '$_[0]' Expression information ; Execute: tad-import.pl -delete $_[0] \n";
		}
	}
}		
		
sub GENES_FPKM { #subroutine for getting gene information
	#INSERT INTO DATABASE: #GeneStats table
	my $ffastbit = fastbit($all_details{'FastBit-path'}, $all_details{'FastBit-foldername'});  #connect to fastbit
	my $gfastbit = $ffastbit."/gene-information"; # specifying the gene section.
	
	$sth = $dbh->prepare("select sampleid from GeneStats where sampleid = '$_[0]'"); $sth->execute(); $found = $sth->fetch();
	unless ($found) { 
		printerr "NOTICE:\t Importing $_[0] to GeneStats table\n";
		$sth = $dbh->prepare("insert into GeneStats (sampleid,date) values (?,?)");
		$sth ->execute($_[0], $date) or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
	} else {
		printerr "NOTICE:\t $_[0] already in GeneStats table... Moving on \n";
	}
	my $genecount = 0;
	$sth = $dbh->prepare("select genestatus from GeneStats where sampleid = '$_[0]' and genestatus ='done'"); $sth->execute(); $found = $sth->fetch();
	unless ($found) {
		`$ibis -d $gfastbit -q 'select count(sampleid) where sampleid = "$_[0]"' -o $nosql 2>>$efile`;
		open(IN,"<",$nosql);
		no warnings;
		chomp($genecount = <IN>);
		close (IN); `rm -rf $nosql`;
		
		#get the organism name and the tissue from the database
		my $species = $dbh->selectrow_array("select a.organism from Animal a join Sample b on a.animalid = b.derivedfrom where b.sampleid = '$_[0]'");
		my $tissue = $dbh->selectrow_array("select tissue from Sample where sampleid = '$_[0]'");
		
		#working on the individual fles
		if ($genesfile){ #working with genes.fpkm_tracking file
			#cufflinks expression tool name
			$diffexpress = "Cufflinks";
			$genes = `cat $genesfile | wc -l`; if ($genes >=2){ $genes--;} else {$genes = 0;} #count the number of genes
			$sth = $dbh->prepare("update GeneStats set genes = $genes, diffexpresstool = '$diffexpress' where sampleid= '$_[0]'"); $sth ->execute(); #updating GeneStats table.
			unless ($genes == $genecount) {
				unless ($genecount == 0 ) {
					$verbose and printerr "NOTICE:\t Removed incomplete records for $_[0] in Genes-NoSQL\n";
		      `$ibis -d $gfastbit -y \"sampleid = '$delete'\" -z 2>> $efile`;
					`rm -rf $gfastbit/*sp $gfastbit/*old $gfastbit/*idx $gfastbit/*dic $gfastbit/*int `; #removing old indexes
				}
				printerr "NOTICE:\t Importing $diffexpress expression information for $_[0] to Genes-NoSQL ...";
				#import into FPKM table;
				open(FPKM, "<", $genesfile) or die "\nERROR:\t Can not open file $genesfile\n";
				open (NOSQL, ">$gnosql");
				while (<FPKM>){
					chomp;
					my ($track, $class, $ref_id, $gene, $gene_name, $tss, $locus, $length, $coverage, $fpkm, $fpkm_low, $fpkm_high, $fpkm_stat ) = split /\t/;
					unless ($track eq "tracking_id"){ #check & specifying undefined variables to null
						if($coverage =~ /-/){$coverage = 0;} if (length $gene < 1) { $gene = "NULL"; } if (length $gene_name < 1) {$gene_name = "NULL";}
						my ($chrom_no, $chrom_start, $chrom_stop) = $locus =~ /^(.+)\:(.+)\-(.+)$/; $chrom_start++;

						print NOSQL "'$_[0]','$chrom_no','$gene','$gene_name','$species','$fpkm_stat','$tissue',$coverage,0,$fpkm,$fpkm_low,$fpkm_high,$chrom_start,$chrom_stop\n";
					}
				} close FPKM;
				close NOSQL; #end of nosql portion
		
				my $execute = "$ardea -d $gfastbit -m 'sampleid:text,chrom:text,geneid:text,genename:text,organism:text,fpkmstatus:char,tissue:text,coverage:double,tpm:double,fpkm:double,fpkmconflow:double,fpkmconfhigh:double,start:int,stop:int' -t $gnosql";
				`$execute 2>> $efile` or die "\nERROR\t: Complication importing Expression information to FastBit, contact $AUTHOR\n";
				`rm -rf $gfastbit/*sp`; #removeing old indexes
				`ibis -d $gfastbit -query "select genename, geneid, sampleid, chrom, tissue, organism" 2>> $efile`; #create a new index based on genename
				`chmod 777 $gfastbit && rm -rf $gnosql`;
				
				printerr " Done\n";
				#set GeneStats to Done
				$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
				$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
			} else {
					$verbose and printerr "NOTICE:\t $_[0] already in Genes-NoSQL ... Moving on \n";
					$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
					$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
					$additional .=  "Optional: To delete '$_[0]' Expression information ; Execute: tad-import.pl -delete $_[0] \n";
			}
		} elsif ($transcriptsgtf){ #using gtf files
			#differential expression tool names
			if (`head -n 1 $transcriptsgtf` =~ /cufflinks/i) { #working with cufflinks transcripts.gtf file
				$diffexpress = "Cufflinks";
				open(FPKM, "<", $transcriptsgtf) or die "\nERROR:\t Can not open file $transcriptsgtf\n";
				(%ARFPKM,%CHFPKM, %BEFPKM, %CFPKM, %DFPKM, %DHFPKM, %DLFPKM, %cfpkm, %dfpkm, %dhfpkm, %dlfpkm)= ();
				my $i=1;
				while (<FPKM>){
					chomp;
					my ($chrom_no, $tool, $typeid, $chrom_start, $chrom_stop, $qual, $orn, $idk, $therest ) = split /\t/;
					if ($typeid =~ /^transcript/){ #check to make sure only transcripts are inputed
						my %Drest = ();
						foreach (split("\";", $therest)) { $_ =~ s/\s+|\s+//g;my($a, $b) = split /\"/; $Drest{$a} = $b;}
						my $dstax;
						if (length $Drest{'gene_id'} > 1) {
							$dstax = "$Drest{'gene_id'}-$chrom_no";} else {$dstax = "xxx".$i++."-$chrom_no";}
						if (exists $CHFPKM{$dstax}){ #chromsome stop
							if ($chrom_stop > $CHFPKM{$dstax}) {
								$CHFPKM{$dstax} = $chrom_stop;
							}
						}else {
							$CHFPKM{$dstax} = $chrom_stop;
						}
						if (exists $BEFPKM{$dstax}){ #chromsome start
							if ($chrom_start < $BEFPKM{$dstax}) {
								$BEFPKM{$dstax} = $chrom_start;
							}
						}else {
							$BEFPKM{$dstax} = $chrom_start;
						}
						unless (exists $CFPKM{$dstax}{$Drest{'cov'}}){ #coverage
							$CFPKM{$dstax}{$Drest{'cov'}}= $Drest{'cov'};
						}unless (exists $DFPKM{$dstax}{$Drest{'FPKM'}}){ #FPKM
							$DFPKM{$dstax}{$Drest{'FPKM'}}= $Drest{'FPKM'};
						}
						unless (exists $DHFPKM{$dstax}{$Drest{'conf_hi'}}){ #FPKM_hi
							$DHFPKM{$dstax}{$Drest{'conf_hi'}}= $Drest{'conf_hi'};
						}
						unless (exists $DLFPKM{$dstax}{$Drest{'conf_lo'}}){ #FPKM_lo
							$DLFPKM{$dstax}{$Drest{'conf_lo'}}= $Drest{'conf_lo'};
						}
						$ARFPKM{$dstax}= "'$_[0]','$chrom_no','$Drest{'gene_id'}','$Drest{'gene_id'}'";
					}
				} close FPKM;
				#sorting the fpkm values and coverage results.
				foreach my $a (keys %DFPKM){
					my $total = 0;
					foreach my $b (keys %{$DFPKM{$a}}) { $total = $b+$total; }
					$dfpkm{$a} = $total;
				}
				foreach my $a (keys %CFPKM){
					my $total = 0;
					foreach my $b (keys %{$CFPKM{$a}}) { $total = $b+$total; }
					$cfpkm{$a} = $total;
				}
				foreach my $a (keys %DHFPKM){
					my $total = 0;
					foreach my $b (keys %{$DHFPKM{$a}}) { $total = $b+$total; }
					$dhfpkm{$a} = $total;
				}
				foreach my $a (keys %DLFPKM){
					my $total = 0;
					foreach my $b (keys %{$DLFPKM{$a}}) { $total = $b+$total; }
					$dlfpkm{$a} = $total;
				}
				#end of sort.
				#insert into database.
				$genes = scalar (keys %ARFPKM);
				$sth = $dbh->prepare("update GeneStats set genes = $genes, diffexpresstool = '$diffexpress' where sampleid= '$_[0]'"); $sth ->execute(); #updating GeneStats table.
				unless ($genes == $genecount) {
					unless ($genecount == 0 ) {
						$verbose and printerr "NOTICE:\t Removed incomplete records for $_[0] in Genes-NoSQL \n";
						`$ibis -d $gfastbit -y \"sampleid = '$_[0]'\" -z 2>> $efile`;
						`rm -rf $gfastbit/*sp $gfastbit/*old $gfastbit/*idx $gfastbit/*dic $gfastbit/*int `; #removing old indexes
					}
					printerr "NOTICE:\t Importing $diffexpress expression information for $_[0] to Genes-NoSQL ...";
					#import into FPKM table;
					open (NOSQL, ">$gnosql");
					foreach my $a (keys %ARFPKM){
						print NOSQL "$ARFPKM{$a},'$species','NULL','$tissue',$cfpkm{$a},0,$dfpkm{$a},$dlfpkm{$a},$dhfpkm{$a},$BEFPKM{$a},$CHFPKM{$a}\n";
					}
					close NOSQL; #end of nosql portion
					
					my $execute = "$ardea -d $gfastbit -m 'sampleid:text,chrom:text,geneid:text,genename:text,organism:text,fpkmstatus:char,tissue:text,coverage:double,tpm:double,fpkm:double,fpkmconflow:double,fpkmconfhigh:double,start:int,stop:int' -t $gnosql";
					`$execute 2>> $efile` or die "\nERROR\t: Complication importing Expression information to FastBit, contact $AUTHOR\n";
					`rm -rf $gfastbit/*sp`; #removeing old indexes
					`ibis -d $gfastbit -query "select genename, geneid, sampleid, chrom, tissue, organism" 2>> $efile`; #create a new index based on genename
					`chmod 777 $gfastbit && rm -rf $gnosql`;
				
					printerr " Done\n";
					#set GeneStats to Done
					$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
					$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
				}	else {
						$verbose and printerr "NOTICE:\t $_[0] already in Genes-NoSQL... Moving on \n";	
						$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
						$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
						$additional .=  "Optional: To delete '$_[0]' Expression information ; Execute: tad-import.pl -delete $_[0] \n";
				}	
			}
			elsif (`head -n 1 $transcriptsgtf` =~ /stringtie/i) { #working with stringtie output
				$gparameters = substr( `head -n 1 $transcriptsgtf`,2,-1 );
				$diffexpress = substr( `head -n 2 $transcriptsgtf | tail -1`,2,-1 );
				open(FPKM, "<", $transcriptsgtf) or die "\nERROR:\t Can not open file $transcriptsgtf\n";
				(%ARFPKM,%CHFPKM, %BEFPKM, %CFPKM, %DFPKM, %TPM, %cfpkm, %dfpkm, %tpm)= ();
				my $i=1;
				while (<FPKM>){
					chomp;
					my ($chrom_no, $tool, $typeid, $chrom_start, $chrom_stop, $qual, $orn, $idk, $therest ) = split /\t/;
					if ($typeid && $typeid =~ /^transcript/){ #check to make sure only transcripts are inputed
						my %Drest = ();
						foreach (split("\";", $therest)) { $_ =~ s/\s+|\s+//g;my($a, $b) = split /\"/; $Drest{$a} = $b;}
						my $dstax;
						if (length $Drest{'gene_id'} > 1) {
							$dstax = "$Drest{'gene_id'}-$chrom_no";} else {$dstax = "xxx".$i++."-$chrom_no";}
						if (exists $CHFPKM{$dstax}){ #chromsome stop
							if ($chrom_stop > $CHFPKM{$dstax}) {
								$CHFPKM{$dstax} = $chrom_stop;
							}
						}else {
							$CHFPKM{$dstax} = $chrom_stop;
						}
						if (exists $BEFPKM{$dstax}){ #chromsome start
							if ($chrom_start < $BEFPKM{$dstax}) {
								$BEFPKM{$dstax} = $chrom_start;
							}
						}else {
							$BEFPKM{$dstax} = $chrom_start;
						}
						unless (exists $CFPKM{$dstax}{$Drest{'cov'}}){ #coverage
							$CFPKM{$dstax}{$Drest{'cov'}}= $Drest{'cov'};
						}unless (exists $DFPKM{$dstax}{$Drest{'FPKM'}}){ #FPKM
							$DFPKM{$dstax}{$Drest{'FPKM'}}= $Drest{'FPKM'};
						}
						unless (exists $TPM{$dstax}{$Drest{'TPM'}}){ #TPM
							$TPM{$dstax}{$Drest{'TPM'}}= $Drest{'TPM'};
						}
						unless ($Drest{'ref_gene_name'}){
							$ARFPKM{$dstax}= "'$_[0]','$chrom_no','$Drest{'gene_id'}','NULL'";
						} else {
							$ARFPKM{$dstax}= "'$_[0]','$chrom_no','$Drest{'gene_id'}','$Drest{'ref_gene_name'}'";
						}
					}
				} close FPKM;
				#sorting the fpkm values and coverage results.
				foreach my $a (keys %DFPKM){
					my $total = 0;
					foreach my $b (keys %{$DFPKM{$a}}) { $total = $b+$total; }
					$dfpkm{$a} = $total;
				}
				foreach my $a (keys %CFPKM){
					my $total = 0;
					foreach my $b (keys %{$CFPKM{$a}}) { $total = $b+$total; }
					$cfpkm{$a} = $total;
				}
				foreach my $a (keys %TPM){
					my $total = 0;
					foreach my $b (keys %{$TPM{$a}}) { $total = $b+$total; }
					$tpm{$a} = $total;
				}
				#end of sort.
				#insert into database.
				$genes = scalar (keys %ARFPKM);
				$sth = $dbh->prepare("update GeneStats set genes = $genes, diffexpresstool = '$diffexpress' where sampleid= '$_[0]'"); $sth ->execute(); #updating GeneStats table.
				$gparameters =~ s/\"//g;
				$sth = $dbh->prepare("update CommandSyntax set expressionsyntax = '$gparameters' where sampleid= '$_[0]'"); $sth ->execute(); #updating CommandSyntax table.
			
				unless ($genes == $genecount) {
					unless ($genecount == 0 ) {
						$verbose and printerr "NOTICE:\t Removed incomplete records for $_[0] in Genes-NoSQL\n";
						`$ibis -d $gfastbit -y \"sampleid = '$_[0]'\" -z 2>> $efile`;
						`rm -rf $gfastbit/*sp $gfastbit/*old $gfastbit/*idx $gfastbit/*dic $gfastbit/*int `; #removing old indexes
					}
					printerr "NOTICE:\t Importing StringTie expression information for $_[0] to Genes-NoSQL ...";
					#import into FPKM table;
					open (NOSQL, ">$gnosql");
					foreach my $a (keys %ARFPKM){
						print NOSQL "$ARFPKM{$a},'$species','NULL','$tissue',$cfpkm{$a},$tpm{$a},$dfpkm{$a},0,0,$BEFPKM{$a},$CHFPKM{$a}\n";
					}
					close NOSQL; #end of nosql portion
					
					my $execute = "$ardea -d $gfastbit -m 'sampleid:text,chrom:text,geneid:text,genename:text,organism:text,fpkmstatus:char,tissue:text,coverage:double,tpm:double,fpkm:double,fpkmconflow:double,fpkmconfhigh:double,start:int,stop:int' -t $gnosql";
					`$execute 2>> $efile` or die "\nERROR\t: Complication importing Expression information to FastBit, contact $AUTHOR\n";
					`rm -rf $gfastbit/*sp`; #removing old indexes
					`ibis -d $gfastbit -query "select genename, geneid, sampleid, chrom, tissue, organism" 2>> $efile`; #create a new index based on genename
					`chmod 777 $gfastbit && rm -rf $gnosql`;
				
					printerr " Done\n";
					#set GeneStats to Done
					$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
					$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
				}	else {
						$verbose and printerr "NOTICE:\t $_[0] already in Genes-NoSQL ... Moving on \n";
						$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
						$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
						$additional .=  "Optional: To delete '$_[0]' Expression information ; Execute: tad-import.pl -delete $_[0] \n";
				}	
			}	else {
				die "\nFAILED:\tCan not identify source of Genes Expression File '$transcriptsgtf', consult documentation.\n";
			}
		} elsif ($diffexpress =~ /kallisto/i) { #working with kallisto output
				open(FPKM, "<", $kallistofile) or die "\nERROR:\t Can not open file $kallistofile\n";
				(%TPM, %tpm) = ();
				my $i=1;
				while (<FPKM>){
					chomp;
					my ($targetid, $length, $eff, $est, $tpm ) = split /\t/;
					$TPM{$targetid}{$tpm} = $tpm;
				} close FPKM;
				#sorting the fpkm values and coverage results.
				foreach my $a (keys %TPM){
					my $total = 0;
					foreach my $b (keys %{$TPM{$a}}) { $total = $b+$total; }
					$tpm{$a} = $total;
				}
				#end of sort.
				#insert into database.
				$genes = scalar (keys %TPM);
				$sth = $dbh->prepare("update GeneStats set genes = $genes, diffexpresstool = '$diffexpress' where sampleid= '$_[0]'"); $sth ->execute(); #updating GeneStats table.
				$gparameters =~ s/\"//g; 
				$sth = $dbh->prepare("insert into CommandSyntax (sampleid, expressionsyntax ) values (?,?)");
				$sth ->execute($_[0], $gparameters) or die "\nERROR:\t Complication in CommandSyntax table, consult documentation\n";
				unless ($genes == $genecount) {
					unless ($genecount == 0 ) {
						$verbose and printerr "NOTICE:\t Removed incomplete records for $_[0] in Genes-NoSQL\n";
						`$ibis -d $gfastbit -y \"sampleid = '$_[0]'\" -z 2>> $efile`;
						`rm -rf $gfastbit/*sp $gfastbit/*old $gfastbit/*idx $gfastbit/*dic $gfastbit/*int `; #removing old indexes
					}
					printerr "NOTICE:\t Importing Kallisto expression information for $_[0] to Genes-NoSQL ...";
					#import into FPKM table;
					open (NOSQL, ">$gnosql");
					foreach my $a (keys %TPM){
						print NOSQL "'$_[0]','NULL','$a','$a','$species','NULL','$tissue',0,$tpm{$a},0,0,0,0,0\n";
					}
					close NOSQL; #end of nosql portion
					
					my $execute = "$ardea -d $gfastbit -m 'sampleid:text,chrom:text,geneid:text,genename:text,organism:text,fpkmstatus:char,tissue:text,coverage:double,tpm:double,fpkm:double,fpkmconflow:double,fpkmconfhigh:double,start:int,stop:int' -t $gnosql";
					`$execute 2>> $efile` or die "\nERROR\t: Complication importing Expression information to FastBit, contact $AUTHOR\n";
					`rm -rf $gfastbit/*sp`; #removing old indexes
					`ibis -d $gfastbit -query "select genename, geneid, sampleid, chrom, tissue, organism" 2>> $efile`; #create a new index based on genename
					`chmod 777 $gfastbit && rm -rf $gnosql`;
				
					printerr " Done\n";
					#set GeneStats to Done
					$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
					$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
				}	else {
						$verbose and printerr "NOTICE:\t $_[0] already in Genes-NoSQL ... Moving on \n";
						$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
						$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
						$additional .=  "Optional: To delete '$_[0]' Expression information ; Execute: tad-import.pl -delete $_[0] \n";
				}	
		}	elsif ($diffexpress =~ /salmon/i) { #working with salmon output
				open(FPKM, "<", $salmonfile) or die "\nERROR:\t Can not open file $salmonfile\n";
				(%TPM, %tpm) = ();
				my $i=1;
				while (<FPKM>){
					chomp;
					my ($targetid, $length, $eff, $tpm, $est ) = split /\t/;
					$TPM{$targetid}{$tpm} = $tpm;
				} close FPKM;
				#sorting the fpkm values and coverage results.
				foreach my $a (keys %TPM){
					my $total = 0;
					foreach my $b (keys %{$TPM{$a}}) { $total = $b+$total; }
					$tpm{$a} = $total;
				}
				#end of sort.
				#insert into database.
				$genes = scalar (keys %TPM);
				$sth = $dbh->prepare("update GeneStats set genes = $genes, diffexpresstool = '$diffexpress' where sampleid= '$_[0]'"); $sth ->execute(); #updating GeneStats table.
				$gparameters =~ s/\"//g;
				$sth = $dbh->prepare("insert into CommandSyntax (sampleid, expressionsyntax ) values (?,?)");
				$sth ->execute($_[0], $gparameters) or die "\nERROR:\t Complication in CommandSyntax table, consult documentation\n";
				
				unless ($genes == $genecount) {
					unless ($genecount == 0 ) {
						$verbose and printerr "NOTICE:\t Removed incomplete records for $_[0] in Genes-NoSQL \n";
						`$ibis -d $gfastbit -y \"sampleid = '$_[0]'\" -z 2>> $efile`;
						`rm -rf $gfastbit/*sp $gfastbit/*old $gfastbit/*idx $gfastbit/*dic $gfastbit/*int `; #removing old indexes
					}
					printerr "NOTICE:\t Importing Salmon expression information for $_[0] to Genes-NoSQL ...";
					#import into FPKM table;
					open (NOSQL, ">$gnosql");
					foreach my $a (keys %TPM){
						print NOSQL "'$_[0]','NULL','$a','$a','$species','NULL','$tissue',0,$tpm{$a},0,0,0,0,0\n";
					}
					close NOSQL; #end of nosql portion
					
					my $execute = "$ardea -d $gfastbit -m 'sampleid:text,chrom:text,geneid:text,genename:text,organism:text,fpkmstatus:char,tissue:text,coverage:double,tpm:double,fpkm:double,fpkmconflow:double,fpkmconfhigh:double,start:int,stop:int' -t $gnosql";
					`$execute 2>> $efile` or die "\nERROR\t: Complication importing Expression information to FastBit, contact $AUTHOR\n";
					`rm -rf $gfastbit/*sp`; #removing old indexes
					`ibis -d $gfastbit -query "select genename, geneid, sampleid, chrom, tissue, organism" 2>> $efile`; #create a new index based on genename
					`chmod 777 $gfastbit && rm -rf $gnosql`;
				
					printerr " Done\n";
					#set GeneStats to Done
					$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
					$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
				}	else {
						$verbose and printerr "NOTICE:\t $_[0] already in Genes-NoSQL ... Moving on \n";
						$sth = $dbh->prepare("update GeneStats set genestatus = 'done' where sampleid = '$_[0]'");
						$sth ->execute() or die "\nERROR:\t Complication in GeneStats table, consult documentation\n";
						$additional .=  "Optional: To delete '$_[0]' Expression information ; Execute: tad-import.pl -delete $_[0] \n";
				}	
		}	else {
			die "\nERROR:\t Can not find gene expression file, making sure transcript / abundance files are present'.\n";
		}
	} else {
		$verbose and printerr "NOTICE:\t $_[0] already in Genes-NoSQL ... Moving on \n";
		$additional .=  "Optional: To delete '$_[0]' Expression information ; Execute: tad-import.pl -delete $_[0] \n";
	}
}

sub DBVARIANT {
	my $toolvariant; undef $vparameters;
	if($_[0]){ open(VARVCF,$_[0]) or die ("\nERROR:\t Can not open variant file $_[0]\n"); } else { die ("\nERROR:\t Can not find variant file. make sure variant file with suffix '.vcf' is present\n"); }
	while (<VARVCF>) {
		chomp;
		if (/^\#/) {
			unless (/\#INFO/ || /\#FORMAT/ || /\#contig/ || /#FORMAT/) {
				if (/Version/) {
					if ($_ =~ /GATK/) {
						$_ =~ /ID\=(.*)\,.*Version\=(.*)\,Date.*CommandLineOptions="(.*)">$/;
						$toolvariant = "GATK v.$2,$1";
						$varianttool = "GATK";
						$vparameters = $3;
					} elsif ($_ =~ /samtools/) {
						$_ =~ /Version\=(.*)\+./;
						$toolvariant = "samtools v.$1";
						$varianttool = "samtools";
					}
				} elsif (/Command/) {
					$_ =~ /Command=(.*)$/;
					unless ($vparameters) {
						$vparameters = $1;
					} else {
						$vparameters .= " | $1";
					}
				} #end assigning toolvariant
			}
		} else {
			my @chrdetails = split "\t";
			my @morechrsplit = split(';', $chrdetails[7]);
			if (((split(':', $chrdetails[9]))[0]) eq '0/1'){$verd = "heterozygous";}
			elsif (((split(':', $chrdetails[9]))[0]) eq '1/1'){$verd = "homozygous";}
			elsif (((split(':', $chrdetails[9]))[0]) eq '1/2'){$verd = "heterozygous alternate";}
			$VCFhash{$chrdetails[0]}{$chrdetails[1]} = "$chrdetails[3]|$chrdetails[4]|$chrdetails[5]|$verd";
		}
	} close VARVCF;
	$sth = $dbh->prepare("insert into VarSummary ( sampleid, varianttool, date) values (?,?,?)");
	$sth ->execute($_[1], $toolvariant, $date) or die "\nERROR:\t Complication in VarSummary table, consult documentation\n";;
	$vparameters =~ s/\"//g;
	$sth = $dbh->prepare("update CommandSyntax set variantsyntax = '$vparameters' where sampleid = '$_[1]'");
	$sth ->execute();

	#VARIANT_RESULTS
	printerr "NOTICE:\t Importing $varianttool variant information for $_[1] to VarResult table ...";
	
	#converting to threads
	undef %HASHDBVARIANT; my $ii = 0;
	foreach my $abc (sort keys %VCFhash) {
		foreach my $def (sort {$a <=> $b} keys %{ $VCFhash{$abc} }) {
			my @vcf = split('\|', $VCFhash{$abc}{$def});
			if ($vcf[3] =~ /,/){
				my $first = split(",",$vcf[1]);
				if (length $vcf[0] == length $first){ $itvariants++; $itsnp++; $variantclass = "SNV"; }
				elsif (length $vcf[0] < length $first) { $itvariants++; $itindel++; $variantclass = "insertion"; }
				else { $itvariants++; $itindel++; $variantclass = "deletion"; }
			}
			elsif (length $vcf[0] == length $vcf[1]){ $itvariants++; $itsnp++; $variantclass = "SNV"; }
			elsif (length $vcf[0] < length $vcf[1]) { $itvariants++; $itindel++; $variantclass = "insertion"; }
			else { $itvariants++; $itindel++; $variantclass = "deletion"; }
		
			#putting variants info into a hash table
			my @hashdbvariant = ($_[1], $abc, $def, $vcf[0], $vcf[1], $vcf[2], $variantclass, $vcf[3]); 
			$HASHDBVARIANT{$ii++} = [@hashdbvariant];
		}
	}
		
	#update variantsummary with counts
	$sth = $dbh->prepare("update VarSummary set totalvariants = $itvariants, totalsnps = $itsnp, totalindels = $itindel where sampleid= '$_[1]'");
	$sth ->execute();

	my @hashdetails = keys %HASHDBVARIANT; #print "First $#hashdetails\n"; die;
	undef @VAR; undef @threads;
	push @VAR, [ splice @hashdetails, 0, 200 ] while @hashdetails; #sub the files to multiple subs
	$queue = new Thread::Queue();
	my $builder=threads->create(\&main); #create thread for each subarray into a thread 
	push @threads, threads->create(\&dbvarprocessor) for 1..5; #execute 5 threads
	$builder->join; #join threads
	foreach (@threads){$_->join;}

	#update variantsummary with counts
	$sth = $dbh->prepare("update VarSummary set status = 'done' where sampleid= '$_[1]'");
	$sth ->execute();
	$sth->finish();
}
sub dbvarprocessor { my $query; while ($query = $queue->dequeue()){ dbvarinput(@$query); } }
sub dbvarinput {
	foreach my $a (@_) { 
		$dbh = mysql($all_details{'MySQL-databasename'}, $all_details{'MySQL-username'}, $all_details{'MySQL-password'}); #connect to mysql
		$sth = $dbh->prepare("insert into VarResult ( sampleid, chrom, position, refallele, altallele, quality, variantclass, zygosity ) values (?,?,?,?,?,?,?,?)");
		$sth -> execute(@{$HASHDBVARIANT{$a}}) or die "\nERROR:\t Complication in VarResult table, consult documentation\n";
	}
}

sub VEPVARIANT {
	my ($chrom, $position);
	if($_[0]){ open(VEP,$_[0]) or die ("\nERROR:\t Can not open vep file $_[0]\n"); } else { die ("\nERROR:\t Can not find VEP file. make sure vep file with suffix '.vep.txt' is present\n"); }
	my $ii = 0; undef %HASHDBVARIANT;
	while (<VEP>) {
		chomp;
		unless (/^\#/) {
			unless (/within_non_coding_gene/i || /coding_unknown/i) {
				my @veparray = split "\t"; #14 columns
				my @extraarray = split(";", $veparray[13]);
				foreach (@extraarray) { my @earray = split "\="; $extra{$earray[0]}=$earray[1]; }
				my @indentation = split("_", $veparray[0]);
				if ($#indentation > 2) { $chrom = $indentation[0]."_".$indentation[1]; $position = $indentation[2]; }
				else { $chrom = $indentation[0]; $position = $indentation[1]; }
				$chrom = "chr".$chrom;
				unless ( $extra{'VARIANT_CLASS'} =~ "SNV" or $extra{'VARIANT_CLASS'} =~ "substitution" ){ $position--; }
				else {
					my @poly = split("/",$indentation[$#indentation]);
					unless ($#poly > 1){ unless (length ($poly[0]) == length($poly[1])){ $position--; } }
				}
				my $geneid = $veparray[3];
				my $transcriptid = $veparray[4];
				my $featuretype = $veparray[5];
				my $consequence = $veparray[6]; 
				if ($consequence =~ /NON_(.*)$/){ $consequence = "NON".$1; } elsif ($consequence =~ /STOP_(.*)$/) {$consequence = "STOP".$1; }
				my $pposition = $veparray[9];
				my $aminoacid = $veparray[10];
				my $codons = $veparray[11];
				my $dbsnp = $veparray[12];
				my $locate = "$_[1],$chrom,$position,$consequence,$geneid,$pposition";
				if ( exists $VEPhash{$locate} ) {
					unless ( $VEPhash{$locate} eq $locate ){ die "\nERROR:\t Duplicate annotation in VEP file, consult documentation\n"; }
				} else {
					$VEPhash{$locate} = $locate;
					if (exists $extra{'SYMBOL'}) { $extra{'SYMBOL'} = uc($extra{'SYMBOL'}); }
					my @hashdbvep = ($_[1], $chrom, $position, $extra{'VARIANT_CLASS'}, $consequence, $geneid, $pposition, $dbsnp, $extra{'SOURCE'}, $extra{'SYMBOL'}, $transcriptid, $featuretype, $extra{'BIOTYPE'}, $aminoacid, $codons);
					$HASHDBVARIANT{$ii++} = [@hashdbvep];
					$DBSNP{$chrom}{$position} = $dbsnp; #updating dbsnp	
				}
			}
		} else { if (/API (version \d+)/){ $annversion = $1;} } #getting VEP version
	}
	close VEP;
	
	#update convert to threads
	my @hashdetails = keys %HASHDBVARIANT; #print "First $#hashdetails\n"; die;
	undef @VAR; undef @threads;
	push @VAR, [ splice @hashdetails, 0, 200 ] while @hashdetails; #sub the files to multiple subs
	$queue = new Thread::Queue();
	my $builder=threads->create(\&main); #create thread for each subarray into a thread 
	push @threads, threads->create(\&dbveprocessor) for 1..5; #execute 5 threads
	$builder->join; #join threads
	foreach (@threads){$_->join;}
	`cat $vnosql* >.temp$vnosql; rm -rf $vnosql*; mv .temp$vnosql $vnosql;`; #merging all files
	
	$sth = $dbh->prepare("update VarSummary set annversion = 'VEP $annversion' where sampleid = '$_[1]'"); $sth ->execute();
}
sub dbveprocessor { my $query; while ($query = $queue->dequeue()){ dbvepinput(@$query); } }
sub dbvepinput {
	$vcount++;
	my $newvcount = $vnosql."$vcount";
	foreach my $a (@_) { 
		$dbh = mysql($all_details{'MySQL-databasename'}, $all_details{'MySQL-username'}, $all_details{'MySQL-password'}); #connect to mysql
		$sth = $dbh->prepare("insert into VarAnnotation ( sampleid, chrom, position, consequence, geneid, proteinposition, source, genename, transcript, feature, genetype, aachange, codonchange ) values (?,?,?,?,?,?,?,?,?,?,?,?,?)");
		my ($vsample,$vchrom, $vposition, $vclass, $vconsequence, $vgeneid, $vpposition, $vdbsnp) = @{$HASHDBVARIANT{$a}}[0..7];
		my @vrest = @{$HASHDBVARIANT{$a}}[8..$#{$HASHDBVARIANT{$a}}];
		$sth->execute($vsample,$vchrom, $vposition, $vconsequence, $vgeneid, $vpposition, @vrest) or die "\nERROR:\t Complication in VarAnnotation table, consult documentation\n";
		$sth = $dbh->prepare("update VarResult set variantclass = '$vclass' where sampleid = '$vsample' and chrom = '$vchrom' and position = $vposition"); $sth ->execute() or die "\nERROR:\t Complication in updating VarResult table, consult documentation\n";
		
		#DBSNP
		if (exists $DBSNP{$vchrom}{$vposition}) {
			$sth = $dbh->prepare("update VarResult set dbsnpvariant = '$vdbsnp' where sampleid = '$vsample' and chrom = '$vchrom' and position = $vposition"); $sth ->execute();
			delete $DBSNP{$vchrom}{$vposition};
		}
		#NOSQL portion
		@nosqlrow = $dbh->selectrow_array("select * from vw_nosql where sampleid = '$vsample' and chrom = '$vchrom' and position = $vposition and consequence = '$vconsequence' and geneid = '$vgeneid' and proteinposition = '$vpposition'");
		$showcase = undef; 
		foreach my $variables (0..$#nosqlrow){
			if ($variables == 2) { $nosqlrow[$variables] = $vdbsnp; }
			if (!($nosqlrow[$variables]) ||(length($nosqlrow[$variables]) < 1) || ($nosqlrow[$variables] =~ /^\-$/) ){
				$nosqlrow[$variables] = "NULL";
			}
			if ($variables < 17) {
				$nosqlrow[$variables] =~ s/^'|'$//g;
				$showcase .= "'$nosqlrow[$variables]',";
			}
			else {
				$showcase .= "$nosqlrow[$variables],";
			}
		}
		chop $showcase; $showcase .= "\n";
		open (NOSQL, ">>$newvcount"); print NOSQL $showcase; close NOSQL; #end of nosql portion
		undef %extra; #making sure extra is blank
	}
}

sub ANNOVARIANT {
	my (%REFGENE, %ENSGENE, %CONTENT);
	my $ii = 0; undef %HASHDBVARIANT;
	if($_[0]){ open(ANNOVAR,$_[0]) or die ("\nERROR:\t Can not open annovar file $_[0]\n"); } else { die ("\nERROR:\t Can not find annovar file. make sure annovar file with suffix '.multianno.txt' is present\n"); }
	my @annocontent = <ANNOVAR>; close ANNOVAR; 
	my @header = split("\t", lc($annocontent[0]));

	#getting headers
	foreach my $no (5..$#header-1){ #checking if ens and ref is specified
		my @tobeheader = split('\.', $header[$no]);
		if ($tobeheader[1] =~ /refgene/i){
			$REFGENE{$tobeheader[0]} = $header[$no];
		} elsif ($tobeheader[1] =~ /ensgene/i){ 
			$ENSGENE{$tobeheader[0]} = $header[$no];
		} else {
			die "ERROR:\t Do not understand notation '$tobeheader[1]' provided. Contact $AUTHOR \n";
		}
	} #end foreach dictionary
	#convert content to a hash array.
	my $counter = $#header+1;
	@annocontent = @annocontent[1..$#annocontent];
	foreach my $rowno (0..$#annocontent) {
		unless ($annocontent[$rowno] =~ /intergenic.*NONE,NONE/i) {
			my @arrayrow = split("\t", $annocontent[$rowno], $counter);
			foreach my $colno (0..$#header) {
				$CONTENT{$rowno}{$header[$colno]} = $arrayrow[$colno];
			}
			$CONTENT{$rowno}{'position'} = (split("\t",$arrayrow[$#arrayrow]))[4];
		} # end unless var annotation is useless
	} #end getting column position o entire file
	#working with ENS
	if (exists $ENSGENE{'func'}) {
		foreach my $newno (sort {$a<=>$b} keys %CONTENT){
			my $pposition = "-"; my $consequence = ""; my $transcript = ""; my $aminoacid = "-"; my $codons = "-";
			if ($CONTENT{$newno}{$ENSGENE{'func'}} =~ /^exonic/i) {
				$consequence = $CONTENT{$newno}{$ENSGENE{'exonicfunc'}};
				unless ($consequence =~ /unknown/i){         
					my @acontent = split(",", $CONTENT{$newno}{$ENSGENE{'aachange'}});
					my @ocontent = split (":", $acontent[$#acontent]);
					$transcript = $ocontent[1] =~ s/\.\d//g;
					foreach (@ocontent){
						if (/^c\.[a-zA-Z]/) {
							my ($a, $b, $c) = $_ =~ /^c\.(\S)(\d+)(\S)$/; 
							$codons = $a."/".$c;
						} elsif (/^c\.[0-9]/) {
							$codons = $_;
						} elsif (/^p\.\S\d+\S$/){ 
							my ($a, $b, $c) = $_ =~ /^p\.(\S)(\d+)(\S)$/;
							$pposition = $b;
							if ($a eq $c) {$aminoacid = $a;} else {$aminoacid = $a."/".$b;}
						} elsif (/^p\.\S\d+\S+$/) {
							my $a = $_ =~ /^p\.\S(\d+)\S+$/;
							$pposition = $a;
							$aminoacid = $_;
						}
					} #end foreach @ocontent
				} else {next;} 
			} else {
				$consequence = $CONTENT{$newno}{$ENSGENE{'func'}};
			}
			unless ($consequence =~ /ncRNA/i) {
				$consequence = uc($consequence);
				if ($consequence eq "UTR5"){ $consequence = "5PRIME_UTR";}
				if ($consequence eq "UTR3"){ $consequence = "3PRIME_UTR";} 
			}
			$CONTENT{$newno}{$ENSGENE{'gene'}} =~ s/\.\d//g; 
			my $locate = "$_[1],$CONTENT{$newno}{'chr'}, $CONTENT{$newno}{'position'},$consequence,$CONTENT{$newno}{$ENSGENE{'gene'}},$pposition";
			if ( exists $ANNOhash{$locate} ) {
				unless ( $ANNOhash{$locate} eq $locate ){ die "\nERROR:\t Duplicate annotation in ANNOVAR file, contact $AUTHOR\n"; }
			} else {
				$ANNOhash{$locate} = $locate;
				my @hashdbanno = ($_[1], $CONTENT{$newno}{'chr'}, $CONTENT{$newno}{'position'}, $consequence, $CONTENT{$newno}{$ENSGENE{'gene'}}, $pposition, 'Ensembl', $transcript, $aminoacid, $codons);
				#$_[1], $chrom, $position, $extra{'VARIANT_CLASS'}, $consequence, $geneid, $pposition, $dbsnp, $extra{'SOURCE'}, $extra{'SYMBOL'}, $transcriptid, $featuretype, $extra{'BIOTYPE'}, $aminoacid, $codons);
				$HASHDBVARIANT{$ii++} = [@hashdbanno];
				#	
				#	$sth = $dbh->prepare("insert into VarAnnotation ( sampleid, chrom, position, consequence, geneid, proteinposition, source, transcript, aachange, codonchange ) values (?,?,?,?,?,?,?,?,?,?)");
				#$sth ->execute($_[1], $CONTENT{$newno}{'chr'}, $CONTENT{$newno}{'position'}, $consequence, 'Ensembl', $CONTENT{$newno}{$ENSGENE{'gene'}}, $transcript, $pposition, $aminoacid, $codons) or die "\nERROR:\t Complication in VarAnnotation table, consult documentation \n";

				##NOSQL portion
				#@nosqlrow = $dbh->selectrow_array("select * from vw_nosql where sampleid = '$_[1]' and chrom = '$CONTENT{$newno}{'chr'}' and position = $CONTENT{$newno}{'position'} and consequence = '$consequence' and geneid = '$CONTENT{$newno}{$ENSGENE{'gene'}}' and proteinposition = '$pposition'");
				#$showcase = undef; 
				#foreach my $variables (0..$#nosqlrow) {
				#	if (!($nosqlrow[$variables]) ||(length($nosqlrow[$variables]) < 1) || ($nosqlrow[$variables] =~ /^\-$/) ){
				#		$nosqlrow[$variables] = "NULL";
				#	}
				#	if ($variables < 17) {
				#		$showcase .= "'$nosqlrow[$variables]',";
				#	}
				#	else {
				#		$showcase .= "$nosqlrow[$variables],";
				#	}
				#}
				#chop $showcase; $showcase .= "\n";
				#open (NOSQL, ">>$vnosql"); print NOSQL $showcase; close NOSQL; #end of nosql portion
			} #end if annohash locate
		} # end foreach looking at content
	} #end if ENSGENE

	#working with REF
	if (exists $REFGENE{'func'}) {
		foreach my $newno (sort {$a<=>$b} keys %CONTENT){
			my $pposition = "-"; my $consequence = ""; my $transcript = ""; my $aminoacid = ""; my $codons = "";
			if ($CONTENT{$newno}{$REFGENE{'func'}} =~ /^exonic/i) {
				$consequence = $CONTENT{$newno}{$REFGENE{'exonicfunc'}};
				unless ($consequence =~ /unknown/i){         
					my @acontent = split(",", $CONTENT{$newno}{$REFGENE{'aachange'}});
					my @ocontent = split (":", $acontent[$#acontent]);
					$transcript = $ocontent[1] =~ s/\.\d//g;
					foreach (@ocontent){
						if (/^c\.[a-zA-Z]/) {
							my ($a, $b, $c) = $_ =~ /^c\.(\S)(\d+)(\S)$/; 
							$codons = $a."/".$c;
						} elsif (/^c\.[0-9]/) {
							$codons = $_;
						} elsif (/^p\.\S\d+\S$/){ 
							my ($a, $b, $c) = $_ =~ /^p\.(\S)(\d+)(\S)$/;
							$pposition = $b;
							if ($a eq $c) {$aminoacid = $a;} else {$aminoacid = $a."/".$b;}
						} elsif (/^p\.\S\d+\S+$/) {
							my $a = $_ =~ /^p\.\S(\d+)\S+$/;
							$pposition = $a;
							$aminoacid = $_;
						}
					}
				} else { next; }
			} else {
				$consequence = $CONTENT{$newno}{$REFGENE{'func'}};
			}
			unless ($consequence =~ /ncRNA/i) {
				$consequence = uc($consequence);
				if ($consequence eq "UTR5"){ $consequence = "5PRIME_UTR";}
				if ($consequence eq "UTR3"){ $consequence = "3PRIME_UTR";} 
			}
			$CONTENT{$newno}{$REFGENE{'gene'}} =~ s/\.\d//g;
			my $locate = "$_[1],$CONTENT{$newno}{'chr'}, $CONTENT{$newno}{'position'},$consequence,$CONTENT{$newno}{$REFGENE{'gene'}},$pposition";
			if ( exists $ANNOhash{$locate} ) {
				unless ( $ANNOhash{$locate} eq $locate ){ die "\nERROR:\t Duplicate annotation in ANNOVAR file, contact $AUTHOR\n"; }
			} else {
				$ANNOhash{$locate} = $locate;
				if (exists $CONTENT{$newno}{$REFGENE{'gene'}}) { $CONTENT{$newno}{$REFGENE{'gene'}} = uc($CONTENT{$newno}{$REFGENE{'gene'}}); }
				my @hashdbanno = ($_[1], $CONTENT{$newno}{'chr'}, $CONTENT{$newno}{'position'}, $consequence, $CONTENT{$newno}{$REFGENE{'gene'}}, $pposition, 'RefSeq', $CONTENT{$newno}{$REFGENE{'gene'}}, $transcript, $aminoacid, $codons);
				#$_[1], $chrom, $position, $extra{'VARIANT_CLASS'}, $consequence, $geneid, $pposition, $dbsnp, $extra{'SOURCE'}, $extra{'SYMBOL'}, $transcriptid, $featuretype, $extra{'BIOTYPE'}, $aminoacid, $codons);
				$HASHDBVARIANT{$ii++} = [@hashdbanno];
				#$sth = $dbh->prepare("insert into VarAnnotation ( sampleid, chrom, position, consequence, geneid, proteinposition, source, genename, transcript, aachange, codonchange ) values (?,?,?,?,?,?,?,?,?,?,?)");
				#if (exists $CONTENT{$newno}{$REFGENE{'gene'}}) { $CONTENT{$newno}{$REFGENE{'gene'}} = uc($CONTENT{$newno}{$REFGENE{'gene'}}); }
				#$sth ->execute($_[1], $CONTENT{$newno}{'chr'}, $CONTENT{$newno}{'position'}, $consequence, 'RefSeq', $CONTENT{$newno}{$REFGENE{'gene'}}, $CONTENT{$newno}{$REFGENE{'gene'}}, $transcript, $pposition, $aminoacid, $codons) or die "\nERROR:\t Complication in VarAnnotation table, consult documentation\n";

				##NOSQL portion
				#@nosqlrow = $dbh->selectrow_array("select * from vw_nosql where sampleid = '$_[1]' and chrom = '$CONTENT{$newno}{'chr'}' and position = $CONTENT{$newno}{'position'} and consequence = '$consequence' and geneid = '$CONTENT{$newno}{$REFGENE{'gene'}}' and proteinposition = '$pposition'");
				#$showcase = undef; 
				#foreach my $variables (0..$#nosqlrow){
				#	if (!($nosqlrow[$variables]) ||(length($nosqlrow[$variables]) < 1) || ($nosqlrow[$variables] =~ /^\-$/) ){
				#		$nosqlrow[$variables] = "NULL";
				#	}
				#	if ($variables < 17) {
				#		$showcase .= "'$nosqlrow[$variables]',";
				#	}
				#	else {
				#		$showcase .= "$nosqlrow[$variables],";
				#	}
				#}
				#chop $showcase; $showcase .= "\n";
				#open (NOSQL, ">>$vnosql"); print NOSQL $showcase; close NOSQL; #end of nosql portion
			} #end if annohash locate
		} # end foreach looking at content
	} #end if REFGENE
	
	#update convert to threads
	my @hashdetails = keys %HASHDBVARIANT; #print "First $#hashdetails\n"; die;
	undef @VAR; undef @threads;
	push @VAR, [ splice @hashdetails, 0, 200 ] while @hashdetails; #sub the files to multiple subs
	$queue = new Thread::Queue();
	my $builder=threads->create(\&main); #create thread for each subarray into a thread 
	push @threads, threads->create(\&dbannorocessor) for 1..5; #execute 5 threads
	$builder->join; #join threads
	foreach (@threads){$_->join;}
	`cat $vnosql* >.temp$vnosql; rm -rf $vnosql*; mv .temp$vnosql $vnosql;`; #merging all files
	
	$sth = $dbh->prepare("update VarSummary set annversion = 'ANNOVAR' where sampleid = '$_[1]'"); $sth ->execute(); #update database annversion :  ANNOVAR
}
sub dbannorocessor { my $query; while ($query = $queue->dequeue()){ dbannoinput(@$query); } }
sub dbannoinput {
	$vcount++;
	my $newvcount = $vnosql."$vcount";
	foreach my $a (@_) { 
		$dbh = mysql($all_details{'MySQL-databasename'}, $all_details{'MySQL-username'}, $all_details{'MySQL-password'}); #connect to mysql
		if ($#{$HASHDBVARIANT{$a}} == 9) { $sth = $dbh->prepare("insert into VarAnnotation ( sampleid, chrom, position, consequence, geneid, proteinposition, source, transcript, aachange, codonchange ) values (?,?,?,?,?,?,?,?,?,?)"); }
		else { $sth = $dbh->prepare("insert into VarAnnotation ( sampleid, chrom, position, consequence, geneid, proteinposition, source, genename, transcript, aachange, codonchange ) values (?,?,?,?,?,?,?,?,?,?,?)"); }
		#print $#{$HASHDBVARIANT{$a}},"\n";
		my ($vsample,$vchrom, $vposition, $vconsequence, $vgeneid, $vpposition) = @{$HASHDBVARIANT{$a}}[0..5];
		my @vrest = @{$HASHDBVARIANT{$a}}[6..$#{$HASHDBVARIANT{$a}}];
		$sth->execute($vsample,$vchrom, $vposition, $vconsequence, $vgeneid, $vpposition, @vrest) or die "\nERROR:\t Complication in VarAnnotation table, consult documentation\n";

		#NOSQL portion
		@nosqlrow = $dbh->selectrow_array("select * from vw_nosql where sampleid = '$vsample' and chrom = '$vchrom' and position = $vposition and consequence = '$vconsequence' and geneid = '$vgeneid' and proteinposition = '$vpposition'");
		$showcase = undef;
		foreach my $variables (0..$#nosqlrow){
			if (!($nosqlrow[$variables]) ||(length($nosqlrow[$variables]) < 1) || ($nosqlrow[$variables] =~ /^\-$/) ){
				$nosqlrow[$variables] = "NULL";
			}
			if ($variables < 17) {
				$showcase .= "'$nosqlrow[$variables]',";
			}
			else {
				$showcase .= "$nosqlrow[$variables],";
			}
		}
		chop $showcase; $showcase .= "\n";
		open (NOSQL, ">>$newvcount"); print NOSQL $showcase; close NOSQL; #end of nosql portion
		undef %extra; #making sure extra is blank
	}
}

sub NOSQL {
	printerr "TASK:\t Importing Variant annotation for $_[0] to NoSQL platform\n"; #status
	my $ffastbit = fastbit($all_details{'FastBit-path'}, $all_details{'FastBit-foldername'});  #connect to fastbit
	my $vfastbit = $ffastbit."/variant-information"; # specifying the variant section.
	printerr "NOTICE:\t Importing $_[0] - Variant Annotation to NoSQL '$ffastbit' ...";
	my $execute = "$ardea -d $vfastbit -m 'variantclass:char,zygosity:char,dbsnpvariant:text,source:text,consequence:text,geneid:text,genename:text,transcript:text,feature:text,genetype:text,refallele:char,altallele:char,tissue:text,chrom:text,aachange:text,codonchange:text,organism:text,sampleid:text,quality:double,position:int,proteinposition:int' -t $vnosql";
	`$execute 2>> $efile` or die "\nERROR\t: Complication importing to FastBit, contact $AUTHOR\n";
	`rm -rf $vfastbit/*sp`; #removing old indexes
	`ibis -d $vfastbit -query "select genename, geneid, genetype, transcript, feature, codonchange, aachange, sampleid, chrom, tissue, organism, consequence, dbsnpvariant, source" 2>> $efile`; #create a new index
	`chmod 777 $vfastbit && rm -rf $vnosql`;
	$sth = $dbh->prepare("update VarSummary set nosql = 'done' where sampleid = '$_[0]'"); $sth ->execute(); #update database nosql : DONE
	
	#removing records from MySQL
	$sth = $dbh->prepare("delete from VarAnnotation where sampleid = '$_[0]'"); $sth->execute();

	#declare done
	printerr " Done\n";
}

sub main {
  foreach my $count (0..$#VAR) {
		while(1) {
			if ($queue->pending() < 100) {
				$queue->enqueue($VAR[$count]);
				last;
			}
		}
	}
	foreach(1..5) { $queue-> enqueue(undef); }
}
#--------------------------------------------------------------------------------


=head1 SYNOPSIS

 tad-import.pl [arguments] <metadata-file|sample-location>

 Optional arguments:
        -h, --help                      print help message
        -m, --man                       print complete documentation
        -v, --verbose                   use verbose output

	Arguments to import metadata or sample analysis
            --metadata			import metadata file provided
            --data2db                	import data files from gene expression profiling and/or variant analysis (default: --gene)
            --delete			delete existing information based on sampleid

        Arguments to control metadata import
    	    -x, --excel         	metadata will import the faang excel file provided (default)
	    -t, --tab         		metadata will import the tab-delimited file provided
 
        Arguments to control data2db import
            --gene	     		data2db will import only the alignment file [TopHat2] and expression profiling files [Cufflinks] (default)
            --variant           	data2db will import only the alignment file [TopHat2] and variant analysis files [.vcf]
	    --all          		data2db will import all data files specified

        Arguments to fine-tune variant import procedure
     	    --vep			import ensembl vep variant annotation file [tab-delimited format] [suffix: .vep.txt] (in variant/all operation)
	    --annovar			import annovar variant annotation file [suffix: .multianno.txt] (in variant/all operation)



 Function: import data files into the database

 Example: #import metadata files
          tad-import.pl -metadata -v example/metadata/FAANG/FAANG_GGA_UD.xlsx
          tad-import.pl -metadata -v -t example/metadata/TEMPLATE/metadata_GGA_UD.txt
 	   
	  #import transcriptome analysis data files
	  tad-import.pl -data2db example/sample_sxt/GGA_UD_1004/
	  tad-import.pl -data2db -all -v example/sample_sxt/GGA_UD_1014/
	  tad-import.pl -data2db -variant -annovar example/sample_sxt/GGA_UD_1004/
		
	  #delete previously imported data data
	  tad-import.pl -delete GGA_UD_1004


 Version: $ Date: 2017-11-01 10:52:40 (Fri, 01 Nov 2017) $

=head1 OPTIONS

=over 8

=item B<--help>

print a brief usage message and detailed explantion of options.

=item B<--man>

print the complete manual of the program.

=item B<--verbose>

use verbose output.

=item B<--metadata>

import metadata file provided.
Metadata files accepted is either a tab-delmited (suffix: '.txt') file 
or FAANG biosamples excel (suffix: '.xls') file

=item B<--tab>

specify the file provided is in tab-delimited format (suffix: '.txt'). (default)

=item B<--excel>

specify the file provided is an excel spreadsheet (suffix: '.xls'/'.xlsx')

=item B<--data2db>

import data files from gene expression profiling analysis 
derived from using TopHat2 or HiSAT2 and Cufflinks or StringTie.
Optionally import variant file (see: variant file format) and 
variant annotation file from annovar or vep.

=item B<--gene>

specify only expression files will be imported. (default)

=item B<--variant>

specify only variant files will be imported.(suffix: '.vcf'))

=item B<--all>

specify both expression and variant files will be imported.

=item B<--vep>

specify annotation file provided was generated using Ensembl Variant Effect Predictor (VEP).

=item B<--annovar>

specify annotation file provided was predicted using ANNOVAR.

=item B<--delete>

delete previously imported information based on sampleid.

=back

=head1 DESCRIPTION

TransAtlasDB is a database management system for organization of gene expression
profiling from numerous amounts of RNAseq data.

TransAtlasDB toolkit comprises of a suite of Perl script for easy archival and 
retrival of transcriptome profiling and genetic variants.

TransAtlasDB requires all analysis be stored in a single folder location for 
successful processing.

Detailed documentation for TransAtlasDB should be viewed on https://modupeore.github.io/TransAtlasDB/.

=over

=item * B<invalid input>

If any of the files input contain invalid arguments or format, TransAtlasDB 
will terminate the program and the invalid input with the outputted. 
Users should manually examine this file and identify sources of error.

=back

=head1 INPUT FILES TYPES

=over 8

=back

=head2 Sample Tab-delimited file

A sample tab-delimited file contains one sample per line, with the fields being sample name,
derived from, organism, organism part, sample description, first name, middle initial,
last name, organization. The 1st four fields (sample name, derived from, organism, organism part)
are required, while the other five fields may contain optional details in regards to the sample.
The 'sample name' must be a word and can be alphanumeric. An example is shown below.

  Sample Name	Derived from	Organism	Organism Part	Sample description	Organization
  GGA_UD_1004	GGA_UD_1004	Gallus gallus	Pituitary gland	21 day male Ross 708	University of Delaware
  GGA_UD_1014	GGA_UD_1014	Gallus gallus	Pituitary gland	21 day male Ross 708	University of Delaware


=head2 Directory/Folder structure

A sample directory structure contains all the files required for successful utilization
of TransAtlasDB, such as the mapping file outputs from either the TopHat2 or
HISAT2 software; expression file outputs from either the Cufflinks or StringTie software;
variant file from any bioinformatics variant analysis package
such as GATK, SAMtools, and (optional) variant annotation results from ANNOVAR 
or Ensembl VEP in tab-delimited format having suffix '.multianno.txt' and '.vep.txt' 
respectively.
The sample directory must be named the same 'sample_name' as with it's corresponding 'sample_name'
in the sample information previously imported.

=over 8

=item * B<TopHat2 and Cufflinks directory structure>
The default naming scheme from the above software are required.
The sub_folders <tophat_folder>,  <cufflinks_folder>, <variant_folder>, <readcounts_folder> are optional.
All files pertaining to such 'sample_name' must be in the same folder.
An example of TopHat and Cufflinks results directory is shown below:

	/sample_name/
	/sample_name/<tophat_folder>/
	/sample_name/<tophat_folder>/accepted_hits.bam
	/sample_name/<tophat_folder>/align_summary.txt
	/sample_name/<tophat_folder>/deletions.bed
	/sample_name/<tophat_folder>/insertions.bed
	/sample_name/<tophat_folder>/junctions.bed
	/sample_name/<cufflinks_folder>/
	/sample_name/<cufflinks_folder>/genes.fpkm_tracking
	/sample_name/<cufflinks_folder>/transcripts.gtf
	/sample_name/<variant_folder>/
	/sample_name/<variant_folder>/<filename>.vcf
	/sample_name/<variant_folder>/<filename>.multianno.txt
	/sample_name/<variant_folder>/<filename>.vep.txt
	/sample_name/<readcounts_folder>/<filename>.counts
	
=item * B<HISAT2 and StringTie directory structure>
The required files from HISAT2 are the BAM mapping file (suffix = '.bam') and the
alignment summary details. The alignment summary is generated as a standard
output, which should be stored in a file named 'align_summary.txt'.
The required file from StringTie is the transcripts file with suffix = '.gtf').
The sub_folders <hisat_folder>,  <stringtie_folder>, <variant_folder>, <readcounts_folder> are optional.
All files pertaining to such 'sample_name' must be in the same folder.
An example of HiSAT2 and Stringtie results directory is shown below:

	/sample_name/
	/sample_name/<hisat_folder>/
	/sample_name/<hisat_folder>/align_summary.txt
	/sample_name/<hisat_folder>/<filename>.bam
	/sample_name/<stringtie_folder>/
	/sample_name/<stringtie_folder>/<filename>.gtf
	/sample_name/<variant_folder>/
	/sample_name/<variant_folder>/<filename>.vcf
	/sample_name/<variant_folder>/<filename>.multianno.txt
	/sample_name/<variant_folder>/<filename>.vep.txt
	/sample_name/<readcounts_folder>/<filename>.counts

=back

=head2 Genomic features or genes read counts file

The genomic features read count files generated from various feature summarization
programs, such as HTseq-count, featureCounts, can be imported into TransAtlasDB.
Read count files must be named with suffix '.counts' to be imported.

=over 8

=back

=head2 Variant file format (VCF)

A sample variant file contains one variant per line, with the fields being chr,
start, end, reference allele, observed allele, other information. The other
information can be anything (for example, it may contain sample identifiers for
the corresponding variant.) An example is shown below:

        16      49303427        49303427        C       T       rs2066844       R702W (NOD2)
        16      49314041        49314041        G       C       rs2066845       G908R (NOD2)
        16      49321279        49321279        -       C       rs2066847       c.3016_3017insC (NOD2)
        16      49290897        49290897        C       T       rs9999999       intronic (NOD2)
        16      49288500        49288500        A       T       rs8888888       intergenic (NOD2)
        16      49288552        49288552        T       -       rs7777777       UTR5 (NOD2)
        18      56190256        56190256        C       T       rs2229616       V103I (MC4R)
				
TransAtlasDB accepts variants file from GATK and SAMtools (BCFtools)

=over 8

=back

--------------------------------------------------------------------------------

TransAtlasDB is free for academic, personal and non-profit use.

For questions or comments, please contact $ Author: Modupe Adetunji <amodupe@udel.edu> $.

=cut


