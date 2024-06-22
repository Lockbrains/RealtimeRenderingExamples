using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SettingPanelControl : MonoBehaviour
{
    public Animator camera2_pos;
    public GameObject camera1, camera2, camera3;
    public GameObject playerGO;
    public GameObject Toggle_weather, Toggle_time;
    public GameObject ContinueButton, img_titles;
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void ContinueOnClick()
    {
        StartCoroutine(ContinueAnimation());
    }

    IEnumerator ContinueAnimation()
    {
        GameManager.S.status = GameManager.GameStatus.GameStart;
        camera2_pos.enabled = true;
        Toggle_weather.SetActive(false);
        Toggle_time.SetActive(false);
        img_titles.SetActive(false);
        ContinueButton.SetActive(false);
        yield return new WaitForSeconds(2.1f);
        camera3.SetActive(true);
        yield return new WaitForSeconds(1.0f);
        playerGO.SetActive(true);
       
        //yield return new WaitForSeconds(0.2f);
        camera3.SetActive(false);
        camera2.SetActive(false);
        camera1.SetActive(false);
    }
}
