all:
	gcc *.m -o spwn.dylib -dynamiclib -framework IOKit 
