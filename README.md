# unfuddler
A simple utility to fiddle with your unfuddle projects using command line

setup your domian, username and password and you are good to go.

options:

	-p to get list of projects
	-m <project id> to get the list of milestones for project.
	-c <project id> to get the list of components for project
	-s <project id> to get the list of severities for project
	-v <project id> to get the list of versions for project
	-f <project id> to get the list of custom field values for project
	-u <project id> <ticket id> <resolved 1/0> <commit_message> to update the status fo the ticket
	-a <project id> <ticket id> <hour> to add a time entry in the ticket specified

creating tickets:

	-t <csv file> <project id> to upload the tickets to unfuddle
	first line of the csv file should be the header.
	summary, description, hour headers are mandatory to define in the csv file. 
	optionally you can put milestone, component, severity, version and priority
	in the csv file or if all the tickets have same properties you can defind below in 
	UNFUDDLE_SETTINGS properties
