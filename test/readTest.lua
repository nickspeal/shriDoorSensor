f = file.open('log.txt', 'w')
f.write("Hello world")
f.write("Hello Again")
f.close()

f2 = file.open('log.txt', 'r')
print(f2.readline())
f2.close()