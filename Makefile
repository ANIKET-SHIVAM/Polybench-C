ICC = icc -xHOST -O3 -parallel -w
#ICC = icc -xHOST -O3 -parallel -par-threshold100 -par-runtime-control3 -w
ICC_s = icc -xHOST -O3 -w
POLLY = clang -march=native -O3 -mllvm -polly -mllvm -polly-vectorizer=stripmine -mllvm -polly-parallel -lgomp -lm
PLUTO_PATH = /home/aniket/pluto-0.11.4/polycc
PLUTO = $(PLUTO_PATH) --tile --parallel -q 
PLUTO_ICC = icc -xHOST -O3 -fopenmp -w
FLAGS = -I utilities utilities/polybench.c -DPOLYBENCH_TIME -DLARGE_DATASET  

ifeq ($(CC), icc)    
	OPT = $(ICC)
else ifeq ($(CC), serial)
	OPT = $(ICC_s)
else ifeq ($(CC), polly)
	OPT = $(POLLY)
else ifeq ($(CC), pluto)
	OPT = $(PLUTO)
	PLUTO_STR = .pluto
else
	OPT = $(ICC)
endif

DM = datamining
LA = linear-algebra
LB = $(LA)/blas
LK = $(LA)/kernels
LS = $(LA)/solvers
ST = stencils
ME = medley

all: dirs compile

DM_BENCHMARKS = correlation covariance
LB_BENCHMARKS = gemm gemver gesummv symm syr2k syrk trmm
LK_BENCHMARKS = 2mm 3mm atax bicg doitgen mvt
LS_BENCHMARKS = cholesky durbin gramschmidt lu ludcmp trisolv
ifeq ($(CC), pluto) #adi is not pluto friendly
	ST_BENCHMARKS = fdtd-2d heat-3d jacobi-1d jacobi-2d seidel-2d
else
	ST_BENCHMARKS = adi fdtd-2d heat-3d jacobi-1d jacobi-2d seidel-2d
endif
ME_BENCHMARKS = deriche floyd-warshall nussinov

compile: datamining linear-algebra-blas linear-algebra-kernels linear-algebra-solvers stencils medley

dirs:
	mkdir -p bin

datamining: $(DM_BENCHMARKS) 
linear-algebra-blas: $(LB_BENCHMARKS)
linear-algebra-kernels: $(LK_BENCHMARKS)
linear-algebra-solvers: $(LS_BENCHMARKS)
stencils: $(ST_BENCHMARKS)
medley: $(ME_BENCHMARKS)

$(DM_BENCHMARKS):
ifeq ($(CC), pluto)
	$(OPT) $(DM)/$@/$@.c
	mv $@$(PLUTO_STR).c  $@$(PLUTO_STR).cloog $(DM)/$@/
	$(PLUTO_ICC) $(FLAGS) -I$(DM)/$@ $(DM)/$@/$@$(PLUTO_STR).c -o bin/$@
else
	$(OPT) $(FLAGS) -I$(DM)/$@ $(DM)/$@/$@$(PLUTO_STR).c -o bin/$@
endif

$(LB_BENCHMARKS):
ifeq ($(CC), pluto)
	$(OPT) $(LB)/$@/$@.c
	mv $@$(PLUTO_STR).c  $@$(PLUTO_STR).cloog $(LB)/$@/
	$(PLUTO_ICC) $(FLAGS) -I$(LB)/$@ $(LB)/$@/$@$(PLUTO_STR).c -o bin/$@
else
	$(OPT) $(FLAGS) -I$(LB)/$@ $(LB)/$@/$@$(PLUTO_STR).c -o bin/$@
endif

$(LK_BENCHMARKS):
ifeq ($(CC), pluto)
	$(OPT) $(LK)/$@/$@.c
	mv $@$(PLUTO_STR).c  $@$(PLUTO_STR).cloog $(LK)/$@/
	$(PLUTO_ICC) $(FLAGS) -I$(LK)/$@ $(LK)/$@/$@$(PLUTO_STR).c -o bin/$@
else
	$(OPT) $(FLAGS) -I$(LK)/$@ $(LK)/$@/$@$(PLUTO_STR).c -o bin/$@
endif

$(LS_BENCHMARKS):
ifeq ($(CC), pluto)
	$(OPT) $(LS)/$@/$@.c
	mv $@$(PLUTO_STR).c  $@$(PLUTO_STR).cloog $(LS)/$@/
	$(PLUTO_ICC) $(FLAGS) -I$(LS)/$@ $(LS)/$@/$@$(PLUTO_STR).c -o bin/$@
else
	$(OPT) $(FLAGS) -I$(LS)/$@ $(LS)/$@/$@$(PLUTO_STR).c -o bin/$@
endif

$(ST_BENCHMARKS):
ifeq ($(CC), pluto)
	$(OPT) $(ST)/$@/$@.c
	mv $@$(PLUTO_STR).c  $@$(PLUTO_STR).cloog $(ST)/$@/
	$(PLUTO_ICC) $(FLAGS) -I$(ST)/$@ $(ST)/$@/$@$(PLUTO_STR).c -o bin/$@
else
	$(OPT) $(FLAGS) -I$(ST)/$@ $(ST)/$@/$@$(PLUTO_STR).c -o bin/$@
endif

$(ME_BENCHMARKS):
ifeq ($(CC), pluto)
	$(OPT) $(ME)/$@/$@.c
	mv $@$(PLUTO_STR).c  $@$(PLUTO_STR).cloog $(ME)/$@/
	$(PLUTO_ICC) $(FLAGS) -I$(ME)/$@ $(ME)/$@/$@$(PLUTO_STR).c -o bin/$@
else
	$(OPT) $(FLAGS) -I$(ME)/$@ $(ME)/$@/$@$(PLUTO_STR).c -o bin/$@
endif

ifndef ($(BIN_PATH))
BIN_PATH = ./bin
endif

run:
	for x in $(BIN_PATH)/*; do ./utilities/time_benchmark.sh $$x; done

clean:
	rm -f ./bin/*
