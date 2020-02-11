# Renormalisation
- The Normalisation of the CustomerCity and the OrderItem tables was pretty straight forward.
Singular Primary Keys and obvious dependencies delivered clear 3 Normal Forms.
-The Product table was more
complex. The Product table contained a repeating group in form of the
Features column, we will assess that a bit later.
But
also, in other columns, the Product table contains a lot of dirty, incomplete and corrupted data.
In the Colour column for example,
there are a few rows that contain a valid colour name string. But
some of the rows inside this column contain strings like “A” or ”XL ”. The last could have meant to
be a size that was wrongly allocated, but that are assumptions. We are in no position to f ill up the
table, based on those assumptions since we are missing specific knowledge and that would
endanger the integrity of the data
- Another example of this kind is the Feature Column. The Feature Column contains Information of
all kinds. Some of them are marked with a specific word like Size or Column. Some of the Colour
features for example list three different columns to choose from. If looking closer, this feature
belongs to a specific product code. In some cases, there exist three different Variant codes for this
product and each of this variant codes lists one of the three mentioned colours in the Colours
column. But in other cases, the colour column is empty for those variant codes. We could guess and
randomly insert a colour per variant code, but thi s also would endanger the integrity of the data.
- In general, this table needs a proper clean up by someone who is inside the organisation and has
ways to get the information needed. The information has to be checked, properly formatted and
maintained. We couldn’t just make assumptions and try to clean up the table based on those. This
could falsify the data and make it inconsistent with other databases inside the organisation.
Because of this we decided to only change the Features column, in order to eliminate the repeating
group. In addition to that, we transformed all missing values or row entries that were representing
missing values to proper NULL.
- The different Features in the Features column were
split by ‘|’. After a proper examination there
were 7 different categories the Features data could be binned into:
    - colour features ’features’: All information that regards the colour of the product or the colour of a
part of the product
    - composition features : All information that regards the texture and materials the product or
part of the product is made of
    - 'age features': All information regarding for which ages this product in build
    - 'timeFeature': All information regarding the time using the product
    - 'weightFeature': All information regarding the weight of the product or part of the product
    - 'lengthSizeFeature': All information regarding the length or the sizes of the product or part
of the product
    - 'description feature': All information that couldn’t be binned into one of the previous categories
- This is not the most elegant split, but we maintain the integrity of the data and the dependency to
the product code.
In order to get the most out of the newly created structure, we strongly recommend a clean up of the
information saved in the product table.
## Indexing
- Indexing is a powerful way to improve the performance of the database. When thinking about
indexes it is important to understand which information is of interest for the company and will most
likely be used to obtain information about.
Presenting an index
to those parameters partitions the data and speeds up the queries that use those
indexes for filtering.
- Looking at the data at hand, MumsNet will most likely be interested to retrieve information,
regarding a specific order or item of that order. Therefore, OrderItemNumber and OrderNumber
should be part of an index. Regarding an Order in General, the company might be interested to
retrieve information about specific customers, which makes CustomerCityId a candidate for an
index. MumsNet might also be intere sted to retrieve information about a product or the variant of a
product, also ProductCode and VariantCode should be indexes.
- Our new structure presents all the above mentioned parameter as primary keys and foreign keys.
A Primary Key constraint automati cally introduces a clustered index to the Primary Key parameter,
which means that all the mentioned parameters are already Indexes in the new presented structure.
Testing the query performance specifically for the above mentioned values with some additiona l
nonclustered index approaches didn’t improve the query performance, so in the end we decided to
leave it with the clustered indexes, created by the Primary Keys.

# Business Solution
- In order to use the
business solution platform you have to restore the database of deliverable one.
Then you have to save the folders of deliverable two and open them as a new project from inside
Microsoft Visual Studio. Then you have to create a new data source of the database in deliverable
one. After that deploy the solution, click on the cube, switch to browser and calculate any of the
required measure with any of the the dimensions
- In addition to the new database structure, we present a ‘proof of concept’
Business Intelligence
Solution to satisfy specific requirements.
We present this solution in form of a cube, that got the right measures and dimensions defined
needed to do the aggregations of interest.
All the data requirements summarized presented 4 meas
ures of interest:
    - NumberOfOrders : This is a count of the number of orders. With the filter functionality it is
possible to filter it by the OrderStatusCode and get for example the Number of cancelled
Orders.
    - OrderPercentageOfTotalOrdersPlaced : This is a co unt of the number of orders filtered by
a dimension, divided by the total number of orders placed. It presents a proportion or
percentage value of the filtered orders to the complete number of orders place.
    - SalesValue : This is the total value per OrderItem . If not used with Product or VariantCode is
rolls back to the OrderNumber and represents the value of an order,
    - Quantity: This measure represents the Quantity of a product. When use on the order level it
sums up the number of total products in that order
- This cube makes it possible to do the calculations of interest for any dimension in a very fast way. It
is extremely flexible and can be used with any combination of measures and dimensions. That
makes it possible to retrieve important business information also for very specific search cases in a
fast way and without having to write a complicated query first.
- In order to use this Business Intelligence Solution properly, you have to open the cube window and
switch to the browser tab. On the left side is a list with measures in the top and dimensions
following after. By dragging those measures and dimensions into the window on the right you can
get the measures of interest aggregated and calculated for the picked dimensions. If you are
interested in one specific value of a dimension, right click on that dimension and add it as a filter.
On the smaller top window you are presented with a lot of filter options.