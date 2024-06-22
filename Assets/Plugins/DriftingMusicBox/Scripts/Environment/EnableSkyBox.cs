using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnableSkyBox : MonoBehaviour
{
    public GameObject[] Skyboxes;

    private int weather_id, time_id;
    // Start is called before the first frame update
    void Start()
    {
        weather_id = 0;
        time_id = 0;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void ChangeWeatherID(int id)
    {
        weather_id = id;
        EnableSkyboxWithId(weather_id * 3 + time_id);
    }

    public void ChangeTimeId(int id)
    {
        time_id = id;
        EnableSkyboxWithId(weather_id * 3 + time_id);
    }

    private void EnableSkyboxWithId(int id)
    {
        for(int i = 0; i<9; i++)
        {
            Skyboxes[i].SetActive(false);
        }

        Skyboxes[id].SetActive(true);
        
    }
}
