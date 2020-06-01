import Bio, pandas
lengths = map(len, Bio.SeqIO.parse('/home/jit/Downloads/setu/see_long/mapped.long.fasta', 'fasta'))
pandas.Series(lengths).hist(color='gray', bins=1000)
