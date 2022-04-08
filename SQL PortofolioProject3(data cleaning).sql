SELECT * FROM PortofolioProject.`nashville housing`;
USE PortofolioProject;
SET SQL_SAFE_UPDATES = 0;

DROP TABLE `nashville housing`;

--                                             Cleaning Data in SQL Queries




-- Standardize date format 

  SELECT PortofolioProject.`nashville housing`.SaleDate, CONVERT(PortofolioProject.`nashville housing`.SaleDate, date)
  FROM PortofolioProject.`nashville housing`;
  
  UPDATE `nashville housing`
  SET `nashville housing`.SaleDate = STR_TO_DATE(`nashville housing`.SaleDate, '%m/%d/%Y');
  
  SELECT `nashville housing`.SaleDate, Convert(`nashville housing`.SaleDate, date) as newdate
  FROM `nashville housing`;
  
   UPDATE `nashville housing`
   SET `nashville housing`.SaleDate = Convert(`nashville housing`.SaleDate, date);
  
  Select `nashville housing`.Saledate 
  From `nashville housing`;


ALTER TABLE `nashville housing`
DROP COLUMN NewDAte;

ALTER TABLE `nashville housing`
ADD NewSaleDate Date;  

ALTER TABLE `nashville housing`
DROP COLUMN SaleDate;

UPDATE `nashville housing`
SET `nashville housing`.NewSaleDate = Convert(`nashville housing`.SaleDate, date);
  



-- Populate Property Address data


-- So the idea is to use the entries that have the same parcelID inorder to populate the property address
-- We can do a self-join

SELECT *
FROM `nashville housing`
-- WHERE PropertyAddress LIKE ''
ORDER BY ParcelID;

SELECT a.ParcelID,a.PropertyAddress, b.ParcelID, b.PropertyAddress, NULLIF(b.PropertyAddress, a.PropertyAddress)
FROM `nashville housing` a
JOIN `nashville housing` b
     ON a.ParcelID = b.ParcelID
     AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress LIKE '';

UPDATE `nashville housing` a                    /* the JOIN UPDATE statement needs to be defined like this and not like it is presented in the tutorial */
JOIN `nashville housing` b
     ON a.ParcelID = b.ParcelID
     AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = NULLIF(b.PropertyAddress, a.PropertyAddress)
WHERE a.PropertyAddress LIKE '' ;






-- Breaking down the column PropertyAddress and OwnerAddress into individual columns (Address, City, State) respectively

SELECT PropertyAddress
FROM `nashville housing`;
-- WHERE PropertyAddress LIKE ''
-- ORDER BY ParcelID;

-- separating the PropertyAddress column


ALTER TABLE `nashville housing`
DROP COLUMN  PropertySplitAddress;

Alter Table `nashville housing`
ADD PropertySplitAddress nvarchar(255);

Update `nashville housing`
SET PropertySplitAddress = Substring(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1);




ALTER TABLE `nashville housing`
DROP COLUMN  PropertySplitCity;

Alter Table `nashville housing`
ADD PropertySplitCity nvarchar(255);

Update `nashville housing`
SET PropertySplitCity = Substring(PropertyAddress,LOCATE(',', PropertyAddress)+1, Length(PropertyAddress));


SELECT * FROM `nashville housing`;

ALTER TABLE `nashville housing`
DROP COLUMN PropertyAddress;




-- separating the OwnerAddress column (now since we want to split the column into 3 columns we can use the friendlier Substring_index() function as follows)


SELECT OwnerAddress
From `nashville housing`;

SELECT
SUBSTRING_INDEX(OwnerAddress,',',1) as OwnerSplitAddress,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2),',',-1) as OwnerSplitCity,
SUBSTRING_INDEX(OwnerAddress,',',-1) as OwnerSplitState
From `nashville housing`;

ALTER TABLE `nashville housing`
DROP COLUMN OwnerSplitState;

Alter Table `nashville housing`
ADD OwnerSplitAddress nvarchar(255);


Alter Table `nashville housing`
ADD OwnerSplitCity nvarchar(255);

Alter Table `nashville housing`
ADD OwnerSplitState nvarchar(255);

Update `nashville housing`
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress,',',1);

Update `nashville housing`
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2),',',-1);

Update `nashville housing`
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress,',',-1);


-- Change Y and N to Yes and No in the 'Sold as vacant' field

Select DISTINCT(SoldasVacant), count(SoldAsVacant)
From `nashville housing`
Group By SoldAsVacant
order by 2;



SELECT SoldAsVacant
, CASE When SoldAsVacant = 'Y' then 'Yes'
       When SoldAsVacant = 'N' then 'No'
       ELSE soldasvacant
       END
From `nashville housing`;


UPDATE `nashville housing`
SET soldasvacant = CASE When SoldAsVacant = 'Y' then 'Yes'
       When SoldAsVacant = 'N' then 'No'
       ELSE soldasvacant
       END;




-- Remove Duplicates (its a better practice to move the duplicate entries into a temp_table insteaad of deleting them)

WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER (Partition By ParcelID,
                        SalePrice,
                        PropertyAddress,
                        NewSaleDate,                                    --     ------->>>> actually cou cant use an update statement in a cte (on sql server you can do that. istead we can do as shown below
                        LegalReference
                        ORDER BY uniqueID) as row_num
FROM `nashville housing`)
SELECT * FROM RowNumCTE
Where row_num > 1;

SELECT * FROM `nashville housing` h1
INNER JOIN 
(
        SELECT *, 
               ROW_NUMBER() OVER(PARTITION BY ParcelID,
                        PropertyAddress,
                        SalePrice,
                        NewSaleDate,                                    --     ------->>>> actually cou cant use an update staement in a cte (on sql server you can do that. istead we can do as shown below
                        LegalReference
                        ORDER BY uniqueID) as row_num
        FROM `nashville housing`) h2 
        ON h1.uniqueID = h2.uniqueID
    WHERE row_num > 1; 



DELETE h1 FROM `nashville housing` h1
INNER JOIN `nashville housing` h2
WHERE
    h1.UniqueID < h2.UniqueID 
    AND h2.NewSaleDate = h1.NewSaleDate
    AND h2.ParcelID = h1.ParcelID
    AND h2.PropertyAddress = h1.PropertyAddress
    AND h2.SalePrice = h1.SalePrice
    AND h2.legalReference = h1.legalReference;


SELECT *, ROW_NUMBER() OVER (Partition By ParcelID,
                        SalePrice,
                        SaleDate,                                    --     ------->>>> actually cou cant use an update staement in a cte (on sql server you can do that. istead we can do as shown below
                        LegalReference
                        ORDER BY uniqueID) as row_num
FROM `nashville housing`
Where row_num > 1
Order By ParcelID;






-- DELETED unsused columns


SELECT * FROM `nashville housing`;

ALTER TABLE `nashville housing`
DROP COLUMN TaxDistrict; 


show open tables where in_use>0;


