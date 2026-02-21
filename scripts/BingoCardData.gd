class_name BingoCardData
extends RefCounted

func generate(size : int) -> Array:
	var arr : Array  = range(1,size*size+1)
	
	randomize()
	
	arr.shuffle()
	
	var grid : Array 
	for i in range(size):
		var row :Array= []
		for j in range(size):
			row.append(arr[i*size+j])
		grid.append(row)
			
	return grid
func generate_arr(size: int, start:int = 1):
	var arr : Array = range(start, size*size+1)
	
	randomize()
	arr.shuffle()
	return arr
