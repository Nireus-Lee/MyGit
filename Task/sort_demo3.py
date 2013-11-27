def sort(list):
	for i in range(len(list)):
		for j in range(1,len(a)-i):
			if a[j-1]>a[j]:
				t = a[j-1]
				a[j-1] = a[j]
				a[j] = t
			j = j+1
		i = i+1
	for i in range(len(list)):
		print list[i]

a = [22,54,1,33,24,71,44]
a = sort(a)
