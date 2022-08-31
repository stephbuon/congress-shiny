import glob
import pickle
import pandas as pd

path = "/scratch/group/pract-txt-mine/sbuongiorno"
pkls = glob.glob("{}/csv_chunk*.pickle".format(path))

header = True
with open("{}/concat_data.csv".format(path), 'a+') as o:
    for pkl in pkls:
        with open(pkl, 'rb') as p:
            df = pickle.load(p)
        df.to_csv(o, header=header)
        header=False
        del 
