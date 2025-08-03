						EXPORT	CUBE_WIREFRAME_DATA


CUBE_WIREFRAME_DATA
						FCB		8		; 8 vtxs
						FCB		-64,-64,-64
						FCB		 64,-64,-64
						FCB		 64, 64,-64
						FCB		-64, 64,-64
						FCB		-64,-64, 64
						FCB		 64,-64, 64
						FCB		 64, 64, 64
						FCB		-64, 64, 64

						FCB		12		; 12 lines

						FCB		1
						FCB		0,1
						FCB		0,0,-64
						FCB		0,-64,0

						FCB		2
						FCB		1,2
						FCB		0,0,-64
						FCB		64,0,0

						FCB		3
						FCB		2,3
						FCB		0,0,-64
						FCB		0,64,0

						FCB		4
						FCB		3,0
						FCB		0,0,-64
						FCB		-64,0,0


						FCB		5
						FCB		4,5
						FCB		0,0,64
						FCB		0,-64,0

						FCB		6
						FCB		5,6
						FCB		0,0,64
						FCB		64,0,0

						FCB		7
						FCB		6,7
						FCB		0,0,64
						FCB		0,64,0

						FCB		1
						FCB		7,4
						FCB		0,0,64
						FCB		-64,0,0


						FCB		2
						FCB		0,4
						FCB		-64,0,0
						FCB		0,-64,0

						FCB		3
						FCB		1,5
						FCB		64,0,0
						FCB		0,-64,0

						FCB		4
						FCB		2,6
						FCB		64,0,0
						FCB		0,64,0

						FCB		5
						FCB		3,7
						FCB		0,64,0
						FCB		-64,0,0
