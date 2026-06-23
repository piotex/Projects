import boto3




data = [1, 2, 3]

def reverse(data):
    for index in range(len(data)-1, -1, -1):
        yield data[index]

print(reverse(data)[0])



def main():
    a = 0


if __name__ == "__main__":
    main()

