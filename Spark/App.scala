package com.sailing
import org.apache.spark.SparkConf
import org.apache.spark._
import org.apache.spark.rdd.RDD
import org.apache.spark.SparkContext
import org.apache.spark.sql.SQLContext
import org.apache.spark.sql.SaveMode
import org.apache.spark.streaming._
import org.apache.spark.streaming.StreamingContext._ 
import org.apache.spark.util.IntParam
import org.apache.spark.storage.StorageLevel
import org.apache.spark.streaming.kafka.KafkaUtils
import org.apache.spark.streaming.kafka._


case class Cars(rxdevice: Integer,longitude: Float,latitude: Float,speed: Float,ax: Float,ay: Float,az: Float)

object App {

  def main(args : Array[String]) {
    val conf = new SparkConf().setMaster("local[4]").setAppName("sailing")
    val ssc = new StreamingContext(conf, Seconds(10))
    val topics = Map[String,Int]("car-data2" -> 2)
    val consumerid = "consumer26"
    val lines = KafkaUtils.createStream(ssc, "52.91.252.11:2181",consumerid, topics)    
  // val lines = ssc.socketTextStream("54.165.216.61", 1080) 
    lines.foreachRDD(rdd => {
         val sqlContext = SQLContextSingleton.getInstance(rdd.sparkContext)
         import sqlContext.implicits._
         val carframe = rdd.map(you =>you._2.split(",")).map(p=>Cars(p(0).toInt,p(1).toFloat,p(2).toFloat,p(3).toFloat,p(4).toFloat,p(5).toFloat,p(6).toFloat)).toDF()
       // carframe.registerTempTable("cars")
          //val secret = sqlContext.sql("select * from cars")
          //secret.show()
         val sumframe = carframe.describe("longitude","latitude","speed","ax","ay","az")
         sumframe.show()
         sumframe.save("/home/ec2-user/sparkoutscala/dataman.json","json",SaveMode.Append)
        }) 

    ssc.start()
    ssc.awaitTermination()

  }

}

object SQLContextSingleton {
    @transient private var instance: SQLContext = _

    def getInstance(sparkContext: SparkContext): SQLContext = {
        if (instance == null) {
            instance = new SQLContext(sparkContext)
        }
        instance
    }
}

