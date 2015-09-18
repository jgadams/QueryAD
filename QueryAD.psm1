# Copyright 2015 Justin Gregory Adams. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and
# the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
# and the following disclaimer in the documentation and/or other materials provided with the
# distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
# THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


##########################################################################################################################################################
## QueryAD.psm1
## Queries a domain controller looking for computers, users, or any filter you choose.
##########################################################################################################################################################


##########################################################################################################################################################
## QueryAD() does the heavy lifting.
## ConnectionString: LDAP connection string, QueryAD() connects to root of current domain if not specified.
## Filter: LDAP search filter, QueryAD() returns all objects if not specified.
## Properties: Object properties to return, QueryAD() returns only "name" property if not specified.
##########################################################################################################################################################
function QueryAD
{
	param([string] $ConnectionString= $null, [string] $Filter= $null, [string[]] $Properties= $null);

	$ou= New-Object System.DirectoryServices.DirectoryEntry($ConnectionString);

	$searcher= New-Object System.DirectoryServices.DirectorySearcher;
	$searcher.SearchRoot= $ou;
	$searcher.PageSize= 1000; # Deal with Active Directory truncating past 1000 items unless PageSize is specified.
	$searcher.SearchScope= "Subtree"; # Search base object and children recursively.

	# Use filter specified in params if given.
	if($Filter -ne $null)
	{
		$searcher.Filter= $Filter;
	}

	# If properties are specified in params, use them. Otherwise, get the name property.
	if($Properties -eq $null)
	{
		$searcher.PropertiesToLoad.Add("name");
	}
	else
	{
		foreach($p in $Properties)
		{
			$searcher.PropertiesToLoad.Add($p);
		}
	}

	return $searcher.FindAll();
}

##########################################################################################################################################################
## Helper function. Not intended for use by end user.
##########################################################################################################################################################
function QueryADNameProperty
{
	param([string] $ConnectionString= $null, [Parameter(Mandatory=$true)] [string] $Filter);

	$results= QueryAD -ConnectionString $ConnectionString -Filter $Filter -Properties "Name";

	$names= @();
	foreach($r in $results)
	{
		$temp= $r.Properties;
		$names += $temp.name;
	}

	[System.Array]::Sort($names);

	return $names;
}

##########################################################################################################################################################
## Get-ADComputerNames()
## Without a ConnectionString parameter, gets all computer names of the current domain. You can also search an arbitrary OU. For example, suppose we have
## a domain controller at dc.RadCompany.net, and we want to search the following OU for computers: "Computers\Northern Division\Business Office"
## We would call the funciton as follows:
## Get-ADComputerNames -ConnectionString "LDAP://dc.RadCompany.net/OU=Business Office,OU=Northern Division,OU=Computers,DC=dc,DC=RadCompany,DC=net"
## The Filter parameter adds specific conditions beyond just computers, see LDAP filter syntax.
##########################################################################################################################################################
function Get-ADComputerNames
{
	param([string] $ConnectionString= $null, [string] $Filter= $null);

	# If Filter param is given, add it to the Computer condtion
	if($Filter -ne $null)
	{
		$f= "(&(objectCategory=Computer)" + $Filter + ")";
	}
	else
	{
		$f= "(objectCategory=Computer)";
	}

	return QueryADNameProperty -ConnectionString $ConnectionString -Filter $f;
}

##########################################################################################################################################################
## Get-ADUserNames()
## Using the same example as above except for users, we would call as follows:
## Get-ADUserNames -ConnectionString "LDAP://dc.RadCompany.net/OU=Business Office,OU=Northern Division,OU=Users,DC=dc,DC=RadCompany,DC=net"
##########################################################################################################################################################
function Get-ADUserNames
{
	param([string] $ConnectionString= $null, [string] $Filter= $null);

	# If Filter param is given, add it to the User condtion
	if($Filter -ne $null)
	{
		$f= "(&(objectCategory=User)" + $Filter + ")";
	}
	else
	{
		$f= "(objectCategory=User)";
	}

	return QueryADNameProperty -ConnectionString $ConnectionString -Filter $f;
}