def cellCompete(states,days):

    n = len(states)
    result = [0]*(n+1)

    for i in range(n):
        result[i] = states[i]
        while (days >0):
            result[0] = 0^states[1]
            result[n-1] = 0^states[n-2]

        for i in range(1,n-2+1):
            result[i] = states[i-1] ^ states[i+1]
        for i in range(n):
           states[i] = result[i]
        days = days-1

    return states

print(cellCompete([1,0,0,0,0,1,0,0], 1) )

print(cellCompete([1,1,1,0,1,1,1,1], 2) )
