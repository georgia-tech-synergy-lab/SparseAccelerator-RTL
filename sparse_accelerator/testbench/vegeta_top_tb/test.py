import numpy as np

M=16
K=4
N=4
BLOCK_SIZE=4
SPARSITY=4

A = np.reshape(np.arange(M*K),(M,K))
B = np.reshape(np.arange(K*N*BLOCK_SIZE//SPARSITY),(K*BLOCK_SIZE//SPARSITY,N))
C = np.reshape(np.arange(M*N),(M,N))


sparse_matrix = np.zeros((M, K*BLOCK_SIZE//SPARSITY))

metadata=0
for i in range(M):
    for j in range(0, K, SPARSITY):
        for k in range(SPARSITY):
            sparse_matrix[i][j*BLOCK_SIZE//SPARSITY+metadata]=A[i][j+k]
            metadata +=1
            if (metadata) == 4:
                metadata = 0

print((sparse_matrix@B+C).ravel().reshape((-1,1)))

# print(A)
print(sparse_matrix)
print(B)
print((sparse_matrix@B+C))